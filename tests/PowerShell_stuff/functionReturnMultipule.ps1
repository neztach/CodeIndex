Function DoThings () {
[hashtable]$return = @{}
 
 $dog = "hey"
 $frog = "yo"
$return.a = $dog
$return.b = $frog
 
return $return
}
 
$result = DoThings
 
$result.msg
$result.status

$result.b