<html>

<head>

<title>WI siRNA Selection Program Registration</title>

<SCRIPT language=JAVASCRIPT src="siRNAhelp.js"></SCRIPT>
 
<script src="https://www.google.com/recaptcha/api.js"></script>
<script>
  function onSubmit(token) {
    document.getElementById("registration").submit();
  }
</script>

</HEAD>

<img src="keep/header_wi_01.jpg" />


<center>



<?php

extract($_POST);
extract($_GET);


//
// Verify Information
//

if (isset($register))
{
	if ($password != $password2)
	{
		// Pasword Not Verified
		
		print "<font face=\"arial\" color=\"000000\">Password was not verified</font>\n";
		print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"2;URL=register.php\">\n";
	}
	else
	{
		// Password Verified
		
		//
		// Connect & Grab Variables
		//

	   $link = mysqli_connect("mysqlHost","mysqlLogin","mysqlPassword") or die("Could not connect");
		mysqli_select_db($link, "sirna") or die("Cannot select db");

		date_default_timezone_set("America/New_York");
		$today = getdate();
		$day = $today["mday"] + 0;
		$month = $today["mon"] + 0;
		$year = $today["year"] + 0;

		$tasto +=0;
	
	
		//
		// Error Checking
		//
		
		if($email == ""|| $login == ""|| $password == "")
		{
			print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"0;URL=register.php?fName=$fName&lName=$lName&email=$email&institution=$institution&address1=$address1&address2=$address2&city=$city&state=$state&zip=$zip&country=$country&login=$login&error=1\">\n";
		}
		else
		{
			//
			// Enter Data into DB
			//
	
			$loginBit = 0;
			
			$LoginCheck = mysqli_query($link, "SELECT login FROM accounts") or die("Could not select from accounts");
			
			while($row = mysqli_fetch_array($LoginCheck))
			{
				if($login == $row["login"])
				{
					$loginBit = 1;
				}
			}
			
			if ($loginBit == 1)
			{
				// Login Already Exists
				
				print "<br><br><center><font face=\"arial\" size=5 color=\"red\">**** Please Select a Different Login ****</font></center><br><br>\n";
				print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"5;URL=register.php\">\n";
			}
			else
			{  
				// Login is Novel
			
				$login = addslashes($login);
				$password = addslashes($password);
				$fName = addslashes($fName);
				$lName = addslashes($lName);
				$institution = addslashes($institution);
				$address1 = addslashes($address1);
				$address2 = addslashes($address2);
				$city = addslashes($city);
				$state = addslashes($state);
				$country = addslashes($country);
				$email2 = addslashes($email);
		
				$LoginsQuery = mysqli_query($link, "SELECT pId FROM logins WHERE rId=$tasto") or die("Could not select from logins");
				while($row = mysqli_fetch_array($LoginsQuery))
				{
					$pId = $row["pId"];
		
					$InsertLogins = mysqli_query($link, "INSERT INTO accounts VALUES($pId, \"$login\", \"$password\")") or die("Could not insert into accounts");
				
					$InsertNames = mysqli_query($link, "INSERT INTO names VALUES($pId, \"$fName\", \"$lName\")") or die("Could not insert into names");
				
					//$InsertInstitutions = mysqli_query($link, "INSERT INTO institutions VALUES($pId, \"$institution\", \"$address1\", \"$address2\", \"$city\", \"$state\", \"$zip\", \"$country\")") or die("Could not insert into institutions");
				
					$InsertEmails = mysqli_query($link, "INSERT INTO emails VALUES($pId, \"$email2\")") or die("Could not insert into emails");
				
					$InsertPermissions = mysqli_query($link, "INSERT INTO permissions VALUES($pId, 1, 0)") or die("Could not insert into permissions");
				
					$InsertCounts = mysqli_query($link, "INSERT INTO counts VALUES($pId, $day, $month, $year,0)") or die("Could not insert into counts");
	
					//
					// Mail Authentication Code
					//
		
					srand((double)microtime() * 1000000);
					$authCode = rand();
		
					$InsertAuthentication = mysqli_query($link, "INSERT INTO authentication VALUES($pId, $authCode)") or die("Could not insert into authentication");
		
					$message = "Welcome to the Whitehead Institute's siRNA prediction tool. To activate your account, please enter the following code when asked upon your first login to the website.\n\nAuthentication Code: " . $authCode . "\n\nIf you did not register for the WI siRNA Tool, please diregard this message.\nIf you experience any problems using your new account, please contact admin@domain.com.";

		
					mail($email,"Welcome to siRNA Selection Program ",$message,"Reply-To: admin@domain.com");
		
					print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"0;URL=home.php\">\n";
				}
			} 
		}
	}
}


//
// Registration Form
//

else
{
	if(! isset($error))
	{
		$fName=$lName=$email=$institution=$address1=$address2=$city=$state=$zip=$country=$login="";
	}
	else
	{
		print "<p><font face=\"arial\" color=\"red\">Please fill out all required (*) fields</font>\n";
	}

	print "<form id=\"registration\", action=\"register.php\" method=\"POST\">\n";
	
	print "<table cellpadding=6>\n";	//master table
	
	print "<tr>\n";
			print "<td colspan=2><font face=\"arial\" color=\"000000\">Shortly after completing the registration form, you should receive an email with an authentication code. If you do not receive this code with 24 hours, please contact</font><img src='./keep/contact.jpg'></td>\n";
		print "</tr>\n";
		
	print "<tr>\n";
		print "<td valign=\"top\">\n";
	
		print "<table>\n";	//sub table
	
		print "<tr>\n";
			print "<td colspan=2><font face=\"arial\" color=\"000000\">Identification Information</font></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td>&nbsp;</td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">First Name: </font></td>\n";
			print "<td><INPUT type=\"text\" size=\"25\" maxlength=\"40\" name=\"fName\" value=\"$fName\"></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">Last Name: </font></td>\n";
			print "<td><INPUT type=\"text\" size=\"25\" maxlength=\"40\" name=\"lName\" value=\"$lName\"></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">* Email: </font></td>\n";
			print "<td><INPUT type=\"text\" size=\"25\" maxlength=\"45\" name=\"email\" value=\"$email\"></td>\n";
		print "</tr>\n";

		print "<tr>\n";
			print "<td>&nbsp;</td>\n\n";
		print "</tr>";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">Login Information</font></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td>&nbsp;</td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">* Login Name: </font></td>\n";
			print "<td><INPUT type=\"text\" size=\"25\" maxlength=\"50\" name=\"login\" value=\"$login\"></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">* Password: </font></td>\n";
			print "<td><INPUT type=\"password\" size=\"25\" maxlength=\"50\" name=\"password\"></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">* Verify Password: </font></td>\n";
			print "<td><INPUT type=\"password\" size=\"25\" maxlength=\"50\" name=\"password2\"></td>\n";
		print "</tr>\n";
	
		print "</table>\n";	//sub table
	
	
		print "</td><td>\n";	//master table
	
	
		print "<table>\n";	//sub table
	
		print "<tr>\n";
			print "<td colspan=2><font face=\"arial\" color=\"000000\">Institution Information</font></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td>&nbsp;</td>\n\n";
		print "</tr>";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">  Institution Name: </font></td>\n";
			print "<td><INPUT type=\"text\" size=\"25\" maxlength=\"50\" name=\"institution\" value=\"$institution\"></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">Address 1: </font></td>\n";
			print "<td><INPUT type=\"text\" size=\"25\" maxlength=\"50\" name=\"address1\" value=\"$address1\"></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">  Address 2: </font></td>\n";
			print "<td><INPUT type=\"text\" size=\"25\" maxlength=\"50\" name=\"address2\" value=\"$address2\"></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">City: </font></td>\n";
			print "<td><INPUT type=\"text\" size=\"25\" maxlength=\"50\" name=\"city\" value=\"$city\"></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">State/Province: </font></td>\n";
			print "<td><INPUT type=\"text\" size=\"25\" maxlength=\"50\" name=\"state\" value=\"$state\"></td>\n";
		print "</tr>\n";
	
		print "<TR>\n";
			print "<td><font face=\"arial\" color=\"000000\">Zip Code: </font></td>\n";
			print "<td><INPUT type=\"text\" size=\"25\" maxlength=\"50\" name=\"zip\" value=\"$zip\"></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">Country: </font></td>\n";
			print "<td><INPUT type=\"text\" size=\"25\" maxlength=\"50\" name=\"country\" value=\"$country\"></td>\n";
		print "</tr>\n";
	
		print "<tr>\n";
			print "<td>&nbsp;</td>\n";
		print "</tr>\n";
	
		//
		// Create pId number
		//

		srand((double)microtime() * 1000000);
		$pId = rand();
	
		srand((double)microtime() * 1000000);
		$rId = rand();
	
		$ip = $_SERVER["REMOTE_ADDR"];
	
		$link = mysqli_connect("mysqlHost","mysqlLogin","mysqlPassword") or die("Could not connect");
		mysqli_select_db($link, "sirna") or die("Cannot select db");
		
		$LoginsInsert = mysqli_query($link, "INSERT INTO logins VALUES($pId, $rId, \"$ip\")") or die("Could not insert into logins");
	
		print "<tr>\n";
			print "<input type=\"hidden\" name=\"register\" value=\"1\">\n";
			print "<input type=\"hidden\" name=\"tasto\" value=\"$rId\">\n"; 	
			//print "<td><input type=\"submit\" value=\"Submit Registration\"></td>\n";
			
			print "<button class='g-recaptcha' \n";
    			print "data-sitekey='6LcTauYpAAAAAFy1edaHZyHwsHuyIsyp-OTCx1bQ'\n";
    			print "data-callback='onSubmit' \n";
    			print "data-action='submit'>Submit</button>\n";
			
			print "<td><input type=\"reset\" value=\"Reset\"></td>\n";
		print "</tr>\n";
	
		print "</table>\n";	//sub table
	
		print "</td>\n";
	print "</tr>\n";

	print "</table>\n";	//master table
	
	print "</form>\n";
	
print <<<END

<table>
<tr>
	<td><font face=arial size=2 color="red">Please Note: All fields marked with an * are required for registration.  <br><br>Users of this web site are limited to 25 queries per day to ensure that all those who wish<br>to use this tool are able to access it without interruption.</font><br><br><font face=arial size=2>
"LIMITATIONS OF USE The use of this site is provided free of charge
 to the research community.  No other use is permitted. For information on the use of this site for a commercial purpose or for other issues relating to Intellectual Property, please contact <img src='keep/contact.jpg' />.
<br>
Use of this site is made available without warranty of any kind, expressed
or implied, including, but not limited to, merchantability or fitness for a
particular purpose. No representation is made that the use of this site
shall not infringe the patent rights, copyrights or other intellectual
property rights of any third party.  In no event shall Whitehead Institute,
its trustees, directors, officers, employees, agents and associates be
liable for incidental or consequential damages or any kind, including
economic damage or injury."
</font></td>
</tr>
</table>

<br>

<table align="center" border=1 cellspacing=1 width=480px bgcolor="#92C5F8">
<tr>
	<td align="center"><a class="internal" href="javascript:help('./keep/about.html')"><font face=arial color=08437E>About</font></a></td>
	<td align="center"><a class="internal" href="javascript:help('./keep/FAQ.html')"><font face=arial color=08437E>FAQ</font></a></td>
	<td align="center"><a class="internal" href="javascript:help('./keep/example.html')"><font face=arial color=08437E>Example</font></a></td>
	<td align="center"><a class="internal" href="javascript:help('./keep/compatibility.html')"><font face=arial color=08437E>Compatibility</font></a></td>
	<td align="center"><a class="internal" href="javascript:help('./keep/disclaimer.html')"><font face=arial color=08437E>Disclaimer</font></a></td>
	<td align="center"><a class="internal" href="javascript:help('./keep/acknowledgements.html')"><font face=arial color=08437E>Acknowledgements</font></a></td>
	<td align="center"><a class="internal" href="home.php"><font face=arial color=08437E>Home</font></a></td>
</tr>
</table>

<br>

<p><font face="arial" color="000000" size="2">Copyright 2004 Whitehead Institute for Biomedical Research. All rights reserved.<br>Comments and suggestions to:</font><img src='./keep/contact.jpg'>

END;

}

?>


</center>

</body>
</html>
