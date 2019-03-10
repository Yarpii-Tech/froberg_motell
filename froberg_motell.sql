
ALTER TABLE `users`
  ADD COLUMN `last_motell` VARCHAR(255) NULL
;

INSERT INTO `addon_account` (name, label, shared) VALUES
  ('motell_black_money','Svarta pengar Motell',0)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
  ('motell','Motell',0)
;

INSERT INTO `datastore` (name, label, shared) VALUES
  ('motell','Motell',0)
;

CREATE TABLE `owned_motell` (

  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `price` double NOT NULL,
  `rented` int(11) NOT NULL,
  `owner` varchar(60) NOT NULL,

  PRIMARY KEY (`id`)
);

CREATE TABLE `motell` (

  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `entering` varchar(255) DEFAULT NULL,
  `exit` varchar(255) DEFAULT NULL,
  `inside` varchar(255) DEFAULT NULL,
  `outside` varchar(255) DEFAULT NULL,
  `ipls` varchar(255) DEFAULT '[]',
  `gateway` varchar(255) DEFAULT NULL,
  `is_single` int(11) DEFAULT NULL,
  `is_room` int(11) DEFAULT NULL,
  `is_gateway` int(11) DEFAULT NULL,
  `room_menu` varchar(255) DEFAULT NULL,
  `price` int(11) NOT NULL,

  PRIMARY KEY (`id`)
);

  INSERT INTO `motell` (`id`, `name`, `label`, `entering`, `exit`, `inside`, `outside`, `ipls`, `gateway`, `is_single`, `is_room`, `is_gateway`, `room_menu`, `price`) VALUES
(1, 'Motell', 'Motell', '{\"y\":-673.84,\"z\":28.21,\"x\":-1477.66}', '{\"x\":151.52,\"y\":-1007.02,\"z\":-99.83}', '{\"y\":-1007.95,\"z\":-99.0,\"x\":151.38}', '{\"y\":-659.21,\"z\":28.75,\"x\":-1458.98}', '[]', NULL, 1, 1, 0, '{\"x\":151.94,\"y\":-1001.34,\"z\":-99.83}', 400000);
;

