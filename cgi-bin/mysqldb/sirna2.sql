-- MySQL dump 10.11
--
-- Host: localhost    Database: sirna2
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
-- Table structure for table `ensembl_hs`
--

DROP TABLE IF EXISTS `ensembl_hs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ensembl_hs` (
  `gene_stable_id` varchar(128) NOT NULL default '',
  `transcript_stable_id` varchar(128) NOT NULL default '',
  `dbprimary_id` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`gene_stable_id`,`transcript_stable_id`,`dbprimary_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `ensembl_mm`
--

DROP TABLE IF EXISTS `ensembl_mm`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ensembl_mm` (
  `gene_stable_id` varchar(128) NOT NULL default '',
  `transcript_stable_id` varchar(128) NOT NULL default '',
  `dbprimary_id` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`gene_stable_id`,`transcript_stable_id`,`dbprimary_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `ensembl_rat`
--

DROP TABLE IF EXISTS `ensembl_rat`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ensembl_rat` (
  `gene_stable_id` varchar(128) NOT NULL default '',
  `transcript_stable_id` varchar(128) NOT NULL default '',
  `dbprimary_id` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`gene_stable_id`,`transcript_stable_id`,`dbprimary_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `hsUnigene`
--

DROP TABLE IF EXISTS `hsUnigene`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hsUnigene` (
  `cluster` varchar(40) NOT NULL default '',
  `acc` varchar(40) NOT NULL default '',
  `gi` int(10) unsigned NOT NULL default '0',
  `uniq_unigene` varchar(40) NOT NULL default '',
  `uniq_acc` varchar(40) default NULL,
  `uniq_gi` int(10) unsigned default '0',
  PRIMARY KEY  (`acc`),
  KEY `cluster` (`cluster`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `mmUnigene`
--

DROP TABLE IF EXISTS `mmUnigene`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `mmUnigene` (
  `cluster` varchar(40) NOT NULL default '',
  `acc` varchar(40) NOT NULL default '',
  `gi` int(10) unsigned NOT NULL default '0',
  `uniq_unigene` varchar(40) NOT NULL default '',
  `uniq_acc` varchar(40) default NULL,
  `uniq_gi` int(10) unsigned default '0',
  PRIMARY KEY  (`acc`),
  KEY `cluster` (`cluster`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `rnUnigene`
--

DROP TABLE IF EXISTS `rnUnigene`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `rnUnigene` (
  `cluster` varchar(40) NOT NULL default '',
  `acc` varchar(40) NOT NULL default '',
  `gi` int(10) unsigned NOT NULL default '0',
  `uniq_unigene` varchar(40) NOT NULL default '',
  `uniq_acc` varchar(40) default NULL,
  `uniq_gi` int(10) unsigned default '0',
  PRIMARY KEY  (`acc`),
  KEY `cluster` (`cluster`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `snp`
--

DROP TABLE IF EXISTS `snp`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `snp` (
  `refsnp` int(4) NOT NULL default '0',
  `mRNA` varchar(15) NOT NULL default '',
  `version` tinyint(1) NOT NULL default '0',
  `pos` int(4) unsigned NOT NULL default '0',
  PRIMARY KEY  (`refsnp`,`mRNA`,`version`,`pos`)
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

-- Dump completed on 2009-11-19 16:36:23
