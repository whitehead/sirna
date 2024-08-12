-- MySQL dump 10.11
--
-- Host: yourHost    Database: entrez_gene
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
-- Table structure for table `gene2accession`
--

DROP TABLE IF EXISTS `gene2accession`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `gene2accession` (
  `primary_id` bigint(20) NOT NULL default '0',
  `tax_id` int(11) default NULL,
  `gene_id` int(11) default NULL,
  `status` varchar(30) default NULL,
  `RNA_nuc_access_version` varchar(30) default NULL,
  `RNA_nuc_gi` varchar(30) default NULL,
  `protein_access_version` varchar(30) default NULL,
  `protein_gi` varchar(30) default NULL,
  `genome_nuc_access_version` varchar(30) default NULL,
  `genome_nuc_gi` varchar(30) default NULL,
  `start_pos_gen_access` varchar(30) default NULL,
  `end_pos_gen_access` varchar(30) default NULL,
  `orientation` varchar(30) default NULL,
  PRIMARY KEY  (`primary_id`),
  KEY `gene2accession_index_nuc` (`RNA_nuc_access_version`),
  KEY `gene2accession_index_tax` (`tax_id`),
  KEY `gene2accession_index` (`gene_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `gene2go`
--

DROP TABLE IF EXISTS `gene2go`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `gene2go` (
  `primary_id` bigint(20) NOT NULL,
  `tax_id` int(11) default NULL,
  `gene_id` int(11) default NULL,
  `go_id` varchar(30) default NULL,
  `evidence` varchar(250) default NULL,
  `qualifier` varchar(250) default NULL,
  `go_term` varchar(250) default NULL,
  `pubmed_ids` varchar(250) default NULL,
  `category` varchar(100) default NULL,
  PRIMARY KEY  (`primary_id`),
  KEY `gene2go_index` (`gene_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `gene2pubmed`
--

DROP TABLE IF EXISTS `gene2pubmed`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `gene2pubmed` (
  `primary_id` bigint(20) NOT NULL default '0',
  `tax_id` int(11) default NULL,
  `gene_id` int(11) default NULL,
  `pubmed_id` varchar(30) default NULL,
  PRIMARY KEY  (`primary_id`),
  KEY `gene2pubmed_index` (`gene_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `gene2refseq`
--

DROP TABLE IF EXISTS `gene2refseq`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `gene2refseq` (
  `primary_id` bigint(20) NOT NULL,
  `tax_id` int(11) default NULL,
  `gene_id` int(11) default NULL,
  `status` varchar(30) default NULL,
  `RNA_nuc_access_version` varchar(30) default NULL,
  `RNA_nuc_gi` varchar(30) default NULL,
  `protein_access_version` varchar(30) default NULL,
  `protein_gi` varchar(30) default NULL,
  `genome_nuc_access_version` varchar(30) default NULL,
  `genome_nuc_gi` varchar(30) default NULL,
  `start_pos_gen_access` varchar(30) default NULL,
  `end_pos_gen_access` varchar(30) default NULL,
  `orientation` varchar(30) default NULL,
  `assembly` varchar(30) default NULL,
  PRIMARY KEY  (`primary_id`),
  KEY `gene2refseq_index_protein` (`protein_access_version`),
  KEY `gene2refseq_index_nuc` (`RNA_nuc_access_version`),
  KEY `gene2refseq_index_tax` (`tax_id`),
  KEY `gene2refseq_index` (`gene_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `gene2sts`
--

DROP TABLE IF EXISTS `gene2sts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `gene2sts` (
  `primary_id` bigint(20) NOT NULL default '0',
  `gene_id` int(11) default NULL,
  `UniSTS_id` varchar(30) default NULL,
  PRIMARY KEY  (`primary_id`),
  KEY `gene2sts_index` (`gene_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `gene2unigene`
--

DROP TABLE IF EXISTS `gene2unigene`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `gene2unigene` (
  `primary_id` bigint(20) NOT NULL default '0',
  `gene_id` int(11) default NULL,
  `unigene_cluster` varchar(30) default NULL,
  PRIMARY KEY  (`primary_id`),
  KEY `gene2unigene_index` (`gene_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `gene_history`
--

DROP TABLE IF EXISTS `gene_history`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `gene_history` (
  `primary_id` bigint(20) NOT NULL default '0',
  `tax_id` int(11) default NULL,
  `gene_id` int(11) default NULL,
  `disc_gene_id` int(11) default NULL,
  `disc_symbol` varchar(30) default NULL,
  PRIMARY KEY  (`primary_id`),
  KEY `gene_history_index` (`gene_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `gene_info`
--

DROP TABLE IF EXISTS `gene_info`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `gene_info` (
  `primary_id` bigint(20) NOT NULL default '0',
  `tax_id` int(11) default NULL,
  `gene_id` int(11) default NULL,
  `symbol` varchar(50) default NULL,
  `locusTag` varchar(30) default NULL,
  `synonyms` text,
  `dbXrefs` varchar(100) default NULL,
  `chromosome` varchar(30) default NULL,
  `map_location` varchar(100) default NULL,
  `description` text,
  `type_of_gene` varchar(30) default NULL,
  `symbol_nomen` varchar(30) default NULL,
  `full_name_nomen` varchar(250) default NULL,
  `status_nomen` varchar(30) default NULL,
  `other_designations` text,
  PRIMARY KEY  (`primary_id`),
  KEY `gene_info_indextax` (`tax_id`),
  KEY `gene_info_indexsym` (`symbol_nomen`),
  KEY `gene_info_index` (`gene_id`),
  KEY `gene_info_index_symbol` (`symbol`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `generifs_basic`
--

DROP TABLE IF EXISTS `generifs_basic`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `generifs_basic` (
  `primary_id` bigint(20) NOT NULL default '0',
  `tax_id` int(11) default NULL,
  `gene_id` int(11) default NULL,
  `pubmed_id` varchar(250) default NULL,
  `last_update` varchar(30) default NULL,
  `description` text,
  PRIMARY KEY  (`primary_id`),
  KEY `generifs_basic_index` (`gene_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `interactions`
--

DROP TABLE IF EXISTS `interactions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `interactions` (
  `primary_id` bigint(20) NOT NULL default '0',
  `1_tax_id` int(11) default NULL,
  `1_gene_id` int(11) default NULL,
  `1_accn_vers` varchar(30) default NULL,
  `1_name` text,
  `keyphrase` varchar(250) default NULL,
  `2_tax_id` int(11) default NULL,
  `2_interactant_id` varchar(30) default NULL,
  `2_interactant_id_type` varchar(30) default NULL,
  `2_accn_vers` varchar(30) default NULL,
  `2_name` text,
  `complex_id` varchar(50) default NULL,
  `complex_id_type` varchar(30) default NULL,
  `complex_name` varchar(250) default NULL,
  `pubmed_id_list` text,
  `last_mod` varchar(30) default NULL,
  `generif_text` text,
  `source_interactant_id` varchar(30) default NULL,
  `source_interactant_id_type` varchar(30) default NULL,
  PRIMARY KEY  (`primary_id`),
  KEY `interactions_index` (`1_gene_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `mim2gene`
--

DROP TABLE IF EXISTS `mim2gene`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `mim2gene` (
  `primary_id` bigint(20) NOT NULL default '0',
  `mim_number` int(11) default NULL,
  `gene_id` int(11) default NULL,
  `type` varchar(30) default NULL,
  PRIMARY KEY  (`primary_id`),
  KEY `mim2gene_index` (`gene_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `refSeqSummary`
--

DROP TABLE IF EXISTS `refSeqSummary`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `refSeqSummary` (
  `primary_id` bigint(20) NOT NULL default '0',
  `gene_id` int(11) default NULL,
  `mrnaAcc` varchar(255) NOT NULL default '',
  `completeness` enum('Unknown','Complete5End','Complete3End','FullLength','IncompleteBothEnds','Incomplete5End','Incomplete3End','Partial') NOT NULL default 'Unknown',
  `summary` text NOT NULL,
  PRIMARY KEY  (`primary_id`),
  KEY `refSeqSummary_indexgene` (`gene_id`),
  KEY `refSeqSummary_index` (`mrnaAcc`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `tax2name`
--

DROP TABLE IF EXISTS `tax2name`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `tax2name` (
  `tax_id` int(11) default NULL,
  `organism` varchar(100) default NULL,
  KEY `tax2name_index` (`tax_id`)
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

-- Dump completed on 2009-11-23 20:56:17
