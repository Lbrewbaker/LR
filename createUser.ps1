Do{
$input = Read-Host -Prompt '1:create users or 2:delete users?'

# set variables
	$computer="localhost"
	$password = "logrhythm!1"
	$users = @(
		# List users here to be created
		"user1"
		"user2"
		"user3"
		"user4"
		"user5"
		"user6"
	)
	
# create users from the array
If ($input -eq 1){

	foreach ($user in $users){

		$objOu = [ADSI]"WinNT://$computer"

		$objUser = $objOU.Create("User", $user)

		$objUser.setpassword($password)

		$objUser.SetInfo()

		$objUser.description = "Test user"

		$objUser.SetInfo()
		
		Write-Host "Created user" $user

	}
	break;
}


ElseIf ($input -eq 2){

	foreach ($user in $users){
	#	Remove-LocalUser -Name $user
	#}
		$objOu = [ADSI]"WinNT://$computer"
		$objUser = $objOU.delete("User", $user)
		Write-Host "Removed user" $user
	}
	
	
	break;
}
Else{

	Write-Host "Invalid Input"

}

}While ($true)
