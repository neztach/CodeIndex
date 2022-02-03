#####################################################################
# Build windows failover cluster with file share witness



################### EDIT VARS #####################################
# Add nodes
$nodes = @("servera", "serverb")

# Cluster info
$clustName = "serverClust01"
$clustIP = "192.168.0.1"

# Cluster OU info
$clusterOUName = "My Test Cluster"
$clusterOUPath = "OU=Clusters,DC=DOMAIN,DC=COM"

# File share witness info 
$fsWitnessPath = "\\someNetwokrShare\FS_CLUSTWITNESS"
###################################################################




####################### STATIC ####################################

# Staic var for DC so we dont have to wait for AD replication
    $ADsrv = "exampleServer.domain.com"


# Create OU for cluster (must have RSAT for AD PS module)
    New-ADOrganizationalUnit -Name $clusterOUName -Path $clusterOUPath -Server $ADsrv


# Move computer objects to new OU
    $nodes | % {
        Get-ADComputer $_ | Move-ADObject -TargetPath "OU=$($clusterOUName),$($clusterOUPath)" -Verbose
    }



# Install cluster feature
    $nodes | %{
	    Install-WindowsFeature –Name Failover-Clustering –IncludeManagementTools -ComputerName $_
    }


# Need to reboot
    Restart-Computer -ComputerName $nodes -Force


# Run validation on nodes
	Test-Cluster –Node $nodes


# Create the cluster (YOU MUST RUN THIS COMMAND FROM A SERVER OF THE SAME OS VERSION (2016,2019) AS THE CLUSTER NODES)
    New-Cluster -Name $clustName -Node $nodes -StaticAddress $clustIP -NoStorage



# Create file share witness directory
    New-Item -Path "$($fsWitnessPath)\" -Name $clustName -ItemType "directory"


# Add computer object to Network share access group so they can see the fileshare root
    $nodes | %{
        Add-ADGroupMember -Identity "SOMEGROUP" -Members "$($_)$" -Server $ADsrv
    }
    Add-ADGroupMember -Identity "SOMEGROUP" -Members "$clustName$" -Server $ADsrv


# Set explicit perms on file share witness (must have NTFS module)
    net use i: $fsWitnessPath
        $nodes | %{
            Add-NTFSAccess -Path i:\$($clustName) -Account "domain.com\$($_)$" -AccessRights Modify -AccessType Allow -AppliesTo SubfoldersAndFilesOnly
        }
        Add-NTFSAccess -Path i:\$($clustName) -Account "domain.com\$($clustName)$" -AccessRights Modify -AccessType Allow -AppliesTo SubfoldersAndFilesOnly
    net use i: /delete /y


# Set cluster quorum (Node and file share is recomended for even number nodes)
    Get-ClusterQuorum -Cluster $clustName
    $fullpath = "$($fsWitnessPath)\$($clustName)"
    Set-ClusterQuorum -NodeAndFileShareMajority "$fullpath" -Cluster $clustName

###################################################################
