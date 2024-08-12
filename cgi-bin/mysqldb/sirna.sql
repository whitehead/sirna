-- MySQL dump 10.11
--
-- Host: yourHost    Database: sirna
-- ------------------------------------------------------
-- Server version	5.0.51a-3ubuntu5.4-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `accounts`
--

DROP TABLE IF EXISTS `accounts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `accounts` (
  `pId` int(11) NOT NULL default '0',
  `login` varchar(25) default NULL,
  `password` varchar(25) default NULL,
  PRIMARY KEY  (`pId`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `authentication`
--

DROP TABLE IF EXISTS `authentication`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `authentication` (
  `pId` int(11) NOT NULL default '0',
  `authCode` int(11) NOT NULL default '0',
  PRIMARY KEY  (`pId`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `conserved_7mer_targets`
--

DROP TABLE IF EXISTS `conserved_7mer_targets`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `conserved_7mer_targets` (
  `refseq` varchar(15) NOT NULL,
  `gene_id` int(11) NOT NULL,
  `mir_family_id` varchar(10) NOT NULL,
  `mir2geneID` int(11) NOT NULL,
  `ratio` int(11) NOT NULL,
  PRIMARY KEY  (`mir_family_id`,`refseq`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `counts`
--

DROP TABLE IF EXISTS `counts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `counts` (
  `pId` int(11) NOT NULL default '0',
  `day` int(11) NOT NULL default '0',
  `month` int(11) NOT NULL default '0',
  `year` int(11) NOT NULL default '0',
  `count` int(11) default NULL,
  PRIMARY KEY  (`pId`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `emails`
--

DROP TABLE IF EXISTS `emails`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `emails` (
  `pId` int(11) NOT NULL default '0',
  `email` varchar(60) default NULL,
  PRIMARY KEY  (`pId`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `institutions`
--

DROP TABLE IF EXISTS `institutions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `institutions` (
  `pId` int(11) NOT NULL default '0',
  `institution` varchar(60) default NULL,
  `address1` varchar(60) default NULL,
  `address2` varchar(60) default NULL,
  `city` varchar(60) default NULL,
  `state` varchar(30) default NULL,
  `zip` varchar(30) default NULL,
  `country` varchar(30) default NULL,
  PRIMARY KEY  (`pId`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `logins`
--

DROP TABLE IF EXISTS `logins`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `logins` (
  `pId` int(11) NOT NULL default '0',
  `rId` int(11) NOT NULL default '0',
  `ip` varchar(15) default NULL,
  PRIMARY KEY  (`pId`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `names`
--

DROP TABLE IF EXISTS `names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `names` (
  `pId` int(11) NOT NULL default '0',
  `fName` varchar(50) default NULL,
  `lName` varchar(50) default NULL,
  PRIMARY KEY  (`pId`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `permissions`
--

DROP TABLE IF EXISTS `permissions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `permissions` (
  `pId` int(11) NOT NULL default '0',
  `permit` tinyint(1) default NULL,
  `authenticate` int(11) NOT NULL default '0',
  PRIMARY KEY  (`pId`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-11-23 21:59:02
