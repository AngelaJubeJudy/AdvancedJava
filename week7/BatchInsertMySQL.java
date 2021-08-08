import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import com.lty3.util.JDBCUtils;

/**
     *   测试不同方式插入100万条订单模拟数据
     *    
     *   表结构： 
     *    CREATE TABLE `orders`  (
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
     */
public class BatchInsertMySQL {
	int upperLimit = 1000000;
	int batch = 1000;
	
	// solution 0: Raw Insertion; 多值（INSERT语句中拼多条记录） 
	public void insertByRaw(){
		long start = System.currentTimeMillis();
		
		Connection conn = JDBCUtils.getConnection();
		Statement st = conn.createStatement();
		String stmp = System.currentTimeMillis() / 1000;
		for(int i = 1 ; i <= upperLimit ; i++){
			String cno = stmp + Integer.toString(i);
			String sql = "insert into orders(contract_number)values('" + cno + "')";
			st.execute(sql);
		}
		
		long end = System.currentTimeMillis();
		System.out.println("SPENT: " + (end - start) + " Millis.");
	}
	
    
    // solution 1: PreparedStatement
	public void insertByPreparedStatement() {
        
        Connection conn = null;
        PreparedStatement ps = null;
		String stmp = System.currentTimeMillis() / 1000;
        try {
            
            long start = System.currentTimeMillis();
            
            conn = JDBCUtils.getConnection();
            String sql = "insert into orders(contract_number)values(?)";
            ps = conn.prepareStatement(sql);
            
            for(int i = 1 ; i <= upperLimit ; i++) { 
				String cno = stmp + Integer.toString(i);
                ps.setObject(1, cno);
                ps.execute();
            }
            
            long end = System.currentTimeMillis();
            System.out.println("SPENT: " + (end - start) + " Millis.");
            
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            JDBCUtils.closeResource(conn, ps);
        }
    }
    

	// solution 2: 批量（PreparedStatement中ADD BATCH）插入
    public void insertByPreparedStatement1() {
        
        Connection conn = null;
        PreparedStatement ps = null;
		String stmp = System.currentTimeMillis() / 1000;
        try {
            
            long start = System.currentTimeMillis();
            
            conn = JDBCUtils.getConnection();
            String sql = "insert into orders(contract_number)values(?)";
            ps = conn.prepareStatement(sql);
            
            for(int i = 1 ; i <= upperLimit ; i++) { 
				String cno = stmp + Integer.toString(i);
                ps.setObject(1, cno);
                ps.addBatch();
                
                if(i % batch == 0) {
                    ps.executeBatch();
					ps.clearBatch();
                }
            }
            
            long end = System.currentTimeMillis();
            System.out.println("SPENT: " + (end - start) + " Millis.");
            
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            JDBCUtils.closeResource(conn, ps);
        }
    }
    
    
    public void insertByPreparedStatement2() {
        
        Connection conn = null;
        PreparedStatement ps = null;
		String stmp = System.currentTimeMillis() / 1000;
        try {
            
            long start = System.currentTimeMillis();
            conn = JDBCUtils.getConnection();
            conn.setAutoCommit(false);
            
            String sql = "insert into orders(contract_number)values(?)";
            ps = conn.prepareStatement(sql);
            
            for(int i = 1 ; i <= upperLimit ; i++) { 
                String cno = stmp + Integer.toString(i);
				ps.setObject(1, cno);
                ps.addBatch();
                
                if(i % batch == 0) {
                    ps.executeBatch();
					ps.clearBatch();
                }
            }
            conn.commit();
			conn.setAutoCommit(true);
            
            long end = System.currentTimeMillis();
            System.out.println("SPENT: " + (end - start) + " Millis.");
            
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            JDBCUtils.closeResource(conn, ps);
        }
    }
	
	
	/**
     *   solution 3: Load Data 原生命令，文本文件直接导入数据
     *   LOAD DATA INFILE '/var/lib/mysql-files/ordersRecords.txt' INTO TABLE orders LINES TERMINATED BY '\r\n';
     *  
	 */
	
}   
