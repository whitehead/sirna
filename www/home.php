<HTML>
<HEAD>
<TITLE>WI siRNA Selection Program</TITLE>
<SCRIPT language=JAVASCRIPT src="siRNAhelp.js"></SCRIPT>


</HEAD>

<img src="keep/header_wi_01.jpg" />

<center>

<?php

extract($_POST);
extract($_GET);

//
// Initial Login
//

if (! isset($login))
{
	//
	// Login Form and Sponsorship Panel
	//

	print "<table width=\"100%\">\n";

	print "<tr>\n";

		// Javascript Menu Bar
		print "<td width=\"20%\" align=\"left\">\n";

print <<<END

                <br />
                <!-- <table align="center" border=1 cellspacing=1 bgcolor="#92C5F8"> -->
                <table align="center" border=0 cellspacing=1 bgcolor="#FFFFFF">
                <!-- <tr><td align="center" width=80><a class="internal" href="javascript:help('./keep/news.html')"><font face=arial color=08437E><img src="keep/news.gif" border=0 /></font></a></td>
                </tr> -->
		<tr><td align="center" width=80><a class="internal" href="javascript:help('./keep/about.html')"><font face=arial color=08437E><img src="keep/about.gif" border=0 /></font></a></td>
                </tr>
		<tr><td align="center" width=80><a class="internal" href="javascript:help('./keep/FAQ.html')"><font face=arial color=08437E><img src="keep/faq.gif" border=0 /></font></a></td>
                </tr>
		<tr><td align="center" width=80><a class="internal" href="javascript:help('./keep/example.html')"><font face=arial color=08437E><img src="keep/example.gif" border=0 /></font></a></td>
                </tr>
		<tr><td align="center" width=80><a class="internal" href="javascript:help('./keep/compatibility.html')"><font face=arial color=08437E><img src="keep/compatibility.gif" border=0 /></font></a></td>
                </tr>
		<tr><td align="center" width=80><a class="internal" href="javascript:help('./keep/disclaimer.html')"><font face=arial color=08437E><img src="keep/disclaimer.gif" border=0 /></font></a></td>
                </tr>
		<tr><td align="center" width=80><a class="internal" href="javascript:help('./keep/acknowledgements.html')"><font face=arial color=08437E><img src="keep/acknowledgements.gif" border=0 /></font></a></td>
		</tr>
             

                <tr>
                    <td><p /></td>
                </tr>
                <tr>
                    <td><p /></td>
                </tr>

     </table>


END;

		print "</td>\n";

		// Logo and login table
		print "<td width=\"50%\" align=\"center\">\n";
		print "<img src=\"keep/animation.gif\" height=\"300\"><br><br>\n";

        print "<form method=\"POST\" action=\"home.php\">\n";

		print "<table>\n";

        print "<tr>\n";
			print "<td align=\"right\"><font face=\"arial\" color=\"000000\"> Enter your login:  </font><input type=\"text\" name=\"login\" size=\"15\" value=\"\" maxlength=\"25\"></td>\n";
		print "</tr>\n";

        print "<tr>\n";
			print "<td  align=\"right\"><font face=\"arial\" color=\"000000\">Enter your password: </font><input type=\"password\" name=\"password\" size=\"15\" value=\"\" maxlength=\"25\"></td>\n";
		print "</tr>\n";

		print "<tr>\n";
			print "<td align=\"right\"><input type=\"submit\" value=\"Login\"></td>\n";
		print "</tr>\n";

		print "<tr>\n";
			print "<td align=\"center\"><a class=\"internal\" href=\"register.php\"><font face=\"arial\" color=\"08437E\">REGISTRATION</font></a><br><br></td>\n";
		print "</tr>\n";

		print "</tr>\n";
			print "<td><a class=\"internal\" href=\"reference.php\"><font face=\"arial\" color=\"08437E\">How To Reference siRNA Selection Program</font></a></td>\n";
		print "</tr>\n";

		print "</table>\n";

		// annocements
		//print '<h2>The siRNA selection program will be down on Tuesday June 18th, 2024 due to some maintenance work. <br>

		print "<h3>This website is no longer being maintained nor updated except for the BLAST databases.</h3><br>";
		print "</form>\n";
		print "</td>\n";
		print "<td> &nbsp</td>\n";

		print "</td>\n";
	print "</tr>\n";

	print "</table>\n";

	//
	// Javascript Menus
	//

print <<<END

		<br>


		<br>

		<p><font face="arial" color="000000" size="2">Copyright 2004 Whitehead Institute for Biomedical Research. All rights
		reserved.<br>Comments and suggestions to: <img src='./keep/contact.jpg'></font>
END;

}
else
{

	$link = mysqli_connect("mysqlHost","mysqlLogin","mysqlPassword") or die("Cannot CONNECT");
	$mysqli = mysqli_select_db($link, "sirna") or die("Cannot SELECT_DB");
	#$q = "SELECT * FROM accounts, permissions WHERE accounts.login =\"$login\" and accounts.password=\"$password\" AND accounts.pId=permissions.pId AND permissions.permit=1";
	$LoginQuery =  mysqli_query( $link, "SELECT * FROM accounts, permissions WHERE accounts.login =\"$login\" and accounts.password=\"$password\" AND accounts.pId=permissions.pId AND permissions.permit=1") or die("Cannot SELECT account 1");
	
	// Check for correct login and password

	if ($row = mysqli_fetch_array ($LoginQuery, MYSQLI_ASSOC))
	{
		$pId = $row["pId"];
		$CountsQuery = mysqli_query($link, "SELECT * FROM counts WHERE pId=$pId") or die("Cannot SELECT count 2");

		while($row3 = mysqli_fetch_array ($CountsQuery, MYSQLI_ASSOC))
		{
                        date_default_timezone_set("America/New_York");
                        
			// Check for number of daily usages
			$today = getdate();
	                $day = $today["mday"] + 0;
                        $month = $today["mon"] + 0;
       		        $year = $today["year"] + 0;

                        
			if ($row3["day"] != $day || $row3["month"] != $month || $row3["year"] != $year)
			{
				$CountDel = mysqli_query($link, "UPDATE counts SET count=0, day=$day, month=$month, year = $year WHERE pId=$pId") or die("Cannot Update counts");
			}
		}

                # person with special permission: no limit on usage
		$pattern2 =  "VIP\.xxx\.edu";
		$pattern3 =  "developer\.xxx\.edu";
		$email = "";
		$SponsorQuery  = mysqli_query($link, "SELECT email FROM emails WHERE pId=$pId") or die("Cannot SELECT FROM emails");
		while ($row_sponsor = mysqli_fetch_array ($SponsorQuery, MYSQLI_ASSOC))
		{
			$email = strtolower($row_sponsor["email"]);
		}


		$CountsQuery2 = mysqli_query($link, "SELECT * FROM counts WHERE pId=$pId") or die("Cannot SELECT count");

		while($row2 = mysqli_fetch_array ($CountsQuery2, MYSQLI_ASSOC))
		{
			// Check for number of daily usages
			if ($row2["count"] <  25 || eregi($pattern3,$email) || eregi($pattern2,$email) )
			{

				srand((double)microtime() * 1000000);
				$rId = rand();

				$ip = $_SERVER["REMOTE_ADDR"];

				$PidQuery = mysqli_query($link, "SELECT pId FROM logins WHERE pId=$pId") or die("Cannot SELECT logins");

				// Check for prior login

				if ($row3 = mysqli_fetch_array ($PidQuery, MYSQLI_ASSOC))
				{
					$LoginsUpdate = mysqli_query($link, "UPDATE logins SET rId=$rId, ip=\"$ip\" WHERE pId=$pId") or die("Cannot UPDATE logins");
				}
				else
				{
					$LoginsInsert = mysqli_query($link, "INSERT INTO logins VALUES($pId, $rId, \"$ip\")") or die("Cannot INSERT logins");
				}

				// Check for prior authentication

				if($row["authenticate"] == 0)
				{
					print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"0;URL=authenticate.php?tasto=$rId \">\n";
				}
				else
				{
					print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"0;URL=siRNA_search.cgi?tasto=$rId \">\n";
				}
			}
			else
			{
				print "<font face=\"arial\" size\"2\">You have exceeded the daily usage limit. Please Login Again Tomorrow</font>";

				print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"2;URL=home.php\">\n";
			}
		}
	}
	else
	{
		print "<table>\n";

		print "<tr>\n";
			print "<td><font face=\"arial\" color=\"000000\">Login Failed</font></td>\n";
		print "</tr>\n";

		print "</table>";

		print "<META HTTP-EQUIV=\"REFRESH\" CONTENT=\"0;URL=home.php\">\n";
	}
}


?>

</center>


	</td>
</tr>
</table>
</div>
</div>
</BODY>
</HTML>
