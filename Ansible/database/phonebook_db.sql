/*
*********************************************************************
phonebook database
*********************************************************************
*/
CREATE DATABASE IF NOT EXISTS `phonebook`;

USE `phonebook`;

/*Table structure for table `phonebook` */

DROP TABLE IF EXISTS `phonebook`;

CREATE TABLE `phonebook` (
  `id` int(9) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `phone` varchar(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


insert  into `phonebook`(`id`,`name`,`email`,`phone`) values 

(111,'Carine Schmitt','schmidtt@yahoo.com','40.32.2555'),

(112,'Jean King','king@business.co.uk','7025551838'),

(114,'Peter McPeterson','PetePete@talktalk.co.uk','03 9520 4555'),

(119,'Rochelle Labrune','r-labrune@gmail.com','(01) 40.67.8555'),

(121,'Jonas Bergulfsen','Jonas@hotmail.com ','07-98 9555');