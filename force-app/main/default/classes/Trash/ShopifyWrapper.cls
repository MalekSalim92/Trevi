public with sharing class ShopifyWrapper {
    public OrderDetails order { get; set; }
    
    public class OrderDetails {
        public String transaction_type;
        public String payment_type;
        public String salesforce_id;
        public String salesforce_object;
        public String sage_customer_id;
        public String sage_order_id;
        public String customer_email;
        public String first_name;
        public String last_name;
        public String billing_street;
        public String billing_city;
        public String billing_postalcode;
        public String billing_state;
        public String billing_country;
        public String phone;
        public String cancel_at;
        public String send_email;
        public String total_amount;
        public String GST;
        public String QST;
        public String HST;
        public String success_status;
        public List<ProductDetails> products;
    }
    
    public class ProductDetails {
        public String sku;
        public Decimal unit_price;
        public Integer quantity;
    }
}