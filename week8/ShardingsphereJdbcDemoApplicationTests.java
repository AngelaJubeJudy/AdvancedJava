@RunWith(SpringRunner.class)
@SpringBootTest
class ShardingsphereJdbcDemoApplicationTests {

    @Autowired
    private OrderMapper orderMapper;

    // 插入
    @Test
    public void addCourse() {
        Order order = new Order();
        
        order.setUserId(1);
        order.setStatus("OK");

        orderMapper.insert(order);
    }

    // 查询
    @Test
    public void findOrder() {
        QueryWrapper<Order> wrapper = new QueryWrapper<>();
        wrapper.eq("orderId", 536241143091850881L);
        orderMapper.selectOne(wrapper);
    }

}