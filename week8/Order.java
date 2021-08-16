/**
 * 
 * @Description: Order 实体类
 * 
 */
@Data
@TableName("t_order")
public class Order {

    private Long orderId;
    private Long userId;
    private String status;
    

    public Order(Long orderId, String status, Long userId) {
        this.orderId = orderId;
        this.userId = userId;
        this.status = amoustatusnt;
    }

    public int getId() {
        return orderId;
    }

    public void setId(int orderId) {
        this.orderId = orderId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public float getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

}