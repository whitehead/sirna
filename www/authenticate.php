<HTML>
<HEAD>

<TITLE>WI siRNA Selection Program</TITLE>
<SCRIPT language=JAVASCRIPT src="./siRNAhelp.js"></SCRIPT>

<!-- ImageReady Preload Script (header_wi.psd) -->
<!-- End Preload Script -->

</HEAD>
<BODY>
<img src="keep/header_wi_01.jpg" />
<center>
<img src="keep/animation.gif" height="300" >

<?php



extract($_POST);
extract($_GET);

$link = mysqli_connect("mysqlHost","mysqlLogin","mysqlPassword") or die("Cannot CONNECT");
mysqli_select_db($link, "sirna") or die("Cannot SELECT_DB");

if (isset($tasto))
{
	$tasto += 0;

	$PermissionsQuery = mysqli_query($link, "SELECT pId FROM logins WHERE rId=$tasto") or die("Cannot SELECT FROM logins");

	while ($row = mysqli_fetch_array($PermissionsQuery))
	{
		if(isset($authCode))
		{
			$authCode += 0;
		
			$CheckAuth = mysqli_query($link, "SELECT logins.pId, authentication.authCode FROM authentication, logins WHERE authentication.pId=logins.pId AND logins.rId=$tasto");
			while($row = mysqli_fetch_array($CheckAuth))
			{

			  if ($row["authCode"] == $authCode)
				{
					$UpdatePermissions = mysqli_query($link, "UPDATE permissions SET authenticate=1 WHERE pId=" . $row["pId"]);
				
					print "<p><font face=\"arial\" size=\"4\">Thank You for Authenticating, Please Login Again</font>\n";
				
					print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"2;URL=home.php\">\n";
				}
				else
				{
					print "<p><font face=\"arial\" size=\"4\">Authentication FAILED, Please Login Again";
				
					print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"2;URL=home.php\">\n";
				}
			}
		}
		else
		{
			print "<form action=\"authenticate.php\" method=\"POST\">\n";
	
			print "<input type=\"hidden\" name=\"tasto\" value=\"$tasto\">\n";
		
			print "<table>\n";
			
			print "<tr>\n";
				print "<td><font face=\"arial\" size=\"2\">Your authentication code can be found in the email you received from us</font></td>\n";
			print "</tr>\n";
	
			print "<tr>\n";
				print "<td><font face=\"arial\" size=\"2\">Enter Authentication Code: </font><INPUT type=\"text\" size=\"11\" maxlength=\"15\" name=\"authCode\"></td>\n";
			print "</tr>\n";
	
			print "<tr>\n"; 	
				print "<td align=\"center\"><input type=\"submit\" value=\"Submit\"></td>\n";
			print "</tr>\n";
	
			print "</table>\n";
	
			print "</form>\n";
		
			print <<<END
		
			<br><br>

			<table align="center" border=1 cellspacing=1 bgcolor="#92C5F8">
			<tr>
				<td align="center" width=80><a class="internal" href="javascript:help('./keep/news.html')"><font face=arial color=08437E>NEWS</font></a></td>
				<td align="center" width=80><a class="internal" href="javascript:help('./keep/about.html')"><font face=arial color=08437E>About</font></a></td>
				<td align="center" width=80><a class="internal" href="javascript:help('./keep/FAQ.html')"><font face=arial color=08437E>FAQ</font></a></td>
				<td align="center" width=80><a class="internal" href="javascript:help('./keep/example.html')"><font face=arial color=08437E>Example</font></a></td>
				<td align="center" width=80><a class="internal" href="javascript:help('./keep/compatibility.html')"><font face=arial color=08437E>Compatibility</font></a></td>
				<td align="center" width=80><a class="internal" href="javascript:help('./keep/disclaimer.html')"><font face=arial color=08437E>Disclaimer</font></a></td>
				<td align="center" width=80><a class="internal" href="javascript:help('./keep/acknowledgements.html')"><font face=arial color=08437E>Acknowledgements</font></a></td>
				<td align="center"><a class="internal" href="home.php"><font face=arial color=08437E>Home</font></a></td>
			</tr>
			</table>

			<br>

			<p><font face="arial" color="000000" size="2">Copyright 2004 Whitehead Institute for Biomedical Research. All rights reserved.<br>Comments and suggestions to: </font><img src='keep/contact.gif'>

		
END;
		}
	}
}
else
{
	
  print "<h2>Please Login into Your Account First</h2>\n";
  
  print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"2;URL=home.php\">\n";
}

?>




</center>	

</BODY>
</HTML>
