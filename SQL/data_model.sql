SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

CREATE SCHEMA IF NOT EXISTS `intrabox` DEFAULT CHARACTER SET utf8 ;
USE `intrabox` ;

-- -----------------------------------------------------
-- Table `intrabox`.`status`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `intrabox`.`status` ;

CREATE  TABLE IF NOT EXISTS `intrabox`.`status` (
  `id_status` INT(11) NOT NULL AUTO_INCREMENT ,
  `name` VARCHAR(45) NOT NULL ,
  PRIMARY KEY (`id_status`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `intrabox`.`user`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `intrabox`.`user` ;

CREATE  TABLE IF NOT EXISTS `intrabox`.`user` (
  `id_user` INT(11) NOT NULL AUTO_INCREMENT ,
  `login` VARCHAR(45) NOT NULL ,
  `admin` TINYINT(1) NOT NULL DEFAULT false ,
  PRIMARY KEY (`id_user`) ,
  UNIQUE INDEX `login_UNIQUE` (`login` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `intrabox`.`deposit`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `intrabox`.`deposit` ;

CREATE  TABLE IF NOT EXISTS `intrabox`.`deposit` (
  `id_deposit` INT(11) NOT NULL AUTO_INCREMENT ,
  `id_user` INT(11) NOT NULL ,
  `download_code` VARCHAR(45) NOT NULL ,
  `area_access_code` VARCHAR(45) NULL DEFAULT NULL ,
  `area_to_email` VARCHAR(45) NULL DEFAULT NULL ,
  `area_size` TINYINT(4) NULL DEFAULT NULL ,
  `opt_acknowledgement` TINYINT(1) NOT NULL DEFAULT '0' ,
  `opt_downloads_report` TINYINT(1) NOT NULL DEFAULT '0' ,
  `opt_comment` TINYTEXT NULL DEFAULT NULL ,
  `opt_password` VARCHAR(64) NULL DEFAULT NULL ,
  `id_status` INT(11) NOT NULL ,
  `expiration_days` TINYINT(4) NOT NULL ,
  `expiration_date` DATETIME NOT NULL ,
  `created_date` DATETIME NOT NULL ,
  `created_ip` VARCHAR(19) NOT NULL ,
  `created_useragent` VARCHAR(150) NOT NULL ,
  PRIMARY KEY (`id_deposit`, `id_user`, `id_status`) ,
  INDEX `fk_deposits_status1` (`id_status` ASC) ,
  INDEX `fk_deposit_user1` (`id_user` ASC) ,
  CONSTRAINT `fk_deposits_status1`
    FOREIGN KEY (`id_status` )
    REFERENCES `intrabox`.`status` (`id_status` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_deposit_user1`
    FOREIGN KEY (`id_user` )
    REFERENCES `intrabox`.`user` (`id_user` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `intrabox`.`file`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `intrabox`.`file` ;

CREATE  TABLE IF NOT EXISTS `intrabox`.`file` (
  `id_file` INT(11) NOT NULL AUTO_INCREMENT ,
  `id_deposit` INT(11) NOT NULL ,
  `name` VARCHAR(60) NOT NULL ,
  `size` FLOAT NOT NULL ,
  `on_server` TINYINT(1) NOT NULL DEFAULT '1' ,
  `name_on_disk` VARCHAR(60) NOT NULL ,
  PRIMARY KEY (`id_file`, `id_deposit`) ,
  INDEX `fk_files_deposits` (`id_deposit` ASC) ,
  CONSTRAINT `fk_files_deposits`
    FOREIGN KEY (`id_deposit` )
    REFERENCES `intrabox`.`deposit` (`id_deposit` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `intrabox`.`download`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `intrabox`.`download` ;

CREATE  TABLE IF NOT EXISTS `intrabox`.`download` (
  `id_download` INT(11) NOT NULL AUTO_INCREMENT ,
  `id_deposit` INT(11) NOT NULL ,
  `id_file` INT(11) NOT NULL ,
  `ip` VARCHAR(19) NOT NULL ,
  `useragent` VARCHAR(150) NOT NULL ,
  `start_date` DATETIME NOT NULL ,
  `end_date` DATETIME NULL DEFAULT NULL ,
  `finished` TINYINT(1) NOT NULL DEFAULT '0' ,
  PRIMARY KEY (`id_download`, `id_deposit`, `id_file`) ,
  INDEX `fk_downloads_files1` (`id_file` ASC, `id_deposit` ASC) ,
  CONSTRAINT `fk_downloads_files1`
    FOREIGN KEY (`id_file` , `id_deposit` )
    REFERENCES `intrabox`.`file` (`id_file` , `id_deposit` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;


-- -----------------------------------------------------
-- Table `intrabox`.`usergroup`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `intrabox`.`usergroup` ;

CREATE  TABLE IF NOT EXISTS `intrabox`.`usergroup` (
  `id_usergroup` INT(11) NOT NULL AUTO_INCREMENT ,
  `rule_type` VARCHAR(45) NOT NULL ,
  `rule` VARCHAR(45) NOT NULL ,
  `name` VARCHAR(45) NOT NULL ,
  `quota` BIGINT(45) NOT NULL ,
  `size_max` BIGINT(45) NOT NULL ,
  `expiration_max` TINYINT(4) NOT NULL ,
  `description` TEXT(45) ,
  `creation_date` DATETIME ,
  PRIMARY KEY (`id_usergroup`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;



INSERT INTO status VALUES (1, 'disponible');
INSERT INTO status VALUES (2, 'expire');
INSERT INTO usergroup VALUES (1, 'LDAP', 'default', 'default', '1073741824', '1073741824', '15', NULL, NULL);