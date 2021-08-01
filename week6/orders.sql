/*

 Source Server         : 10.200.2.187【测试环境】
 Source Server Type    : MySQL
 Source Server Version : 50646
 Source Host           : 10.200.2.187:3306
 Source Schema         : ecommerce_app

 Target Server Type    : MySQL
 Target Server Version : 50646
 File Encoding         : 65001
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for orders
-- ----------------------------
DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders`  (
  `id` varchar(64) CHARACTER SET utf8 NOT NULL,
  `account_id` varchar(64) CHARACTER SET utf8 DEFAULT NULL,
  `contract_number` varchar(64) CHARACTER SET utf8 NOT NULL,
  `region` varchar(64) CHARACTER SET utf8 DEFAULT NULL,
  `order_type` varchar(64) CHARACTER SET utf8 DEFAULT NULL,
  `order_price` float(64,2) DEFAULT NULL,
  `product_id` varchar(64) CHARACTER SET utf8 DEFAULT NULL,
  `product_type` varchar(64) CHARACTER SET utf8 DEFAULT NULL,
  `product_info` text CHARACTER SET utf8,
  `billing_model` varchar(64) CHARACTER SET utf8 DEFAULT NULL,
  `service_count` int(11) DEFAULT NULL,
  `delivery_status` varchar(64) CHARACTER SET utf8 DEFAULT NULL,
  `create_at` datetime DEFAULT NULL,
  `update_at` datetime DEFAULT NULL,
  `deleted` varchar(11) DEFAULT NULL,
  PRIMARY KEY (`id`,`contract_number`),
  KEY `account_id` (`account_id`),
  KEY `contract_number` (`contract_number`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_bin ROW_FORMAT = Compact;

SET FOREIGN_KEY_CHECKS = 1;
