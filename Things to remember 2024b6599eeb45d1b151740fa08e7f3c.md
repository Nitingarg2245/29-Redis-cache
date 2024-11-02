# Things to remember

[Future VS CompletableFuture](https://medium.com/@ahmed.abdelfaheem/future-vs-completablefuture-f0ce8f0bcd09)

[springboot+microservices.xlsx](springbootmicroservices.xlsx)

```java

```

https://www.youtube.com/watch?v=flrTe6Zepi0

https://www.youtube.com/watch?v=jYC3OSU4GF4

[https://medium.com/munchy-bytes/introduction-to-date-time-api-in-java-8-574a8df34912#:~:text=An instance of the current time can be created using,now() method.&text=14%3A07%3A12.503202341-,By using of or parse method we can create an,LocalTime for a specific time.&text=Similar to LocalDate%2C we can,an instance of a LocalTime](https://medium.com/munchy-bytes/introduction-to-date-time-api-in-java-8-574a8df34912#:~:text=An%20instance%20of%20the%20current%20time%20can%20be%20created%20using,now()%20method.&text=14%3A07%3A12.503202341-,By%20using%20of%20or%20parse%20method%20we%20can%20create%20an,LocalTime%20for%20a%20specific%20time.&text=Similar%20to%20LocalDate%2C%20we%20can,an%20instance%20of%20a%20LocalTime).

**spring-security**

This tutorial will provide a step-by-step guide to implementing these features in your Spring Boot application. You will learn how to configure Spring Security to work with JWT, define data models and associations for authentication and authorization, use Spring Data JPA to interact with H2 Database, and create REST controllers. You will also learn how to handle exceptions, define payloads, and run and check your application.

The tutorial will cover the following topics:

- **Spring Security**: A powerful and highly customizable authentication and access-control framework.
- **OAuth JWT**: A secure and efficient way to handle authentication and authorization between different parties.
- **HttpOnly Cookie**: A cookie attribute that prevents client-side scripts from accessing the cookie.
- **AuthFilter**: A filter that intercepts requests and performs authentication and authorization checks.
- **H2 Database**: A lightweight and fast in-memory database that supports SQL and JDBC.
- **Login Logout**: A mechanism to authenticate and de-authenticate users. RefreshToken Access Token: A technique to refresh the access token without requiring the user to re-authenticate.

OAuth2 and JWT serve different purposes. OAuth2 defines a protocol that specifies how tokens are transferred, while JWT defines a token format

**Part 1: Project Setup :**

1. Spring Initializer : [https://start.spring.io/](https://start.spring.io/)
2. Dependency : `web`, `lombock`, `validation`, `h2`, `jpa`, `oauth2`, `configuration-processor`
    
    ```
        implementation 'org.springframework.boot:spring-boot-starter-web'
        compileOnly 'org.projectlombok:lombok'
        annotationProcessor 'org.projectlombok:lombok'
        testImplementation 'org.springframework.boot:spring-boot-starter-test'
    
        //Validation
        implementation 'org.springframework.boot:spring-boot-starter-validation'
    
        //Database:
        runtimeOnly 'com.h2database:h2' // You can use any sql database
        implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    
        //security:
        //jwt
        implementation 'org.springframework.boot:spring-boot-starter-oauth2-resource-server'
        annotationProcessor 'org.springframework.boot:spring-boot-configuration-processor'
    
    ```
    
3. `application.yml` : Database Setup
    
    ```
    spring:
      h2:
        console:
          enabled: true
      datasource:
        url: jdbc:h2:mem:atquilDB
        username: sa
        password:
        driverClassName: org.h2.Driver
      jpa:
        spring.jpa.database-platform: org.hibernate.dialect.H2Dialect
        show-sql: true
        hibernate:
          ddl-auto: create-drop
    logging:
      level:
        org.springframework.security: trace
    ```
    

**Part 2: Store User using JPA**

1. Create a `UserInfoEntity` to store User details.
    
    ```
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Entity
    @Table(name="USER_INFO")
    public class UserInfoEntity {
        @Id
        @GeneratedValue
        private Long id;
    
        @Column(name = "USER_NAME")
        private String userName;
    
        @Column(nullable = false, name = "EMAIL_ID", unique = true)
        private String emailId;
    
        @Column(nullable = false, name = "PASSWORD")
        private String password;
    
        @Column(name = "MOBILE_NUMBER")
        private String mobileNumber;
    
        @Column(nullable = false, name = "ROLES")
        private String roles;
    
    }
    ```
    
2. Create a file `UserInfoRepo` in `repo` package, to create `jpa-mapping` using hibernate.
    
    ```
    @Repository
    public interface UserInfoRepo extends JpaRepository<UserInfoEntity,Long> {
    }
    ```
    
3. Create a `UserInfoConfig` class which implements `UserDetails` interface, which **provides core user information which is later encapsulated into Authentication objects.**
    
    ```
    @RequiredArgsConstructor
    public class UserInfoConfig implements UserDetails {
        private final UserInfoEntity userInfoEntity;
        @Override
        public Collection<? extends GrantedAuthority> getAuthorities() {
            return Arrays
                    .stream(userInfoEntity
                            .getRoles()
                            .split(","))
                    .map(SimpleGrantedAuthority::new)
                    .toList();
        }
    
        @Override
        public String getPassword() {
            return userInfoEntity.getPassword();
        }
    
        @Override
        public String getUsername() {
            return userInfoEntity.getEmailId();
        }
    
        @Override
        public boolean isAccountNonExpired() {
            return true;
        }
    
        @Override
        public boolean isAccountNonLocked() {
            return true;
        }
    
        @Override
        public boolean isCredentialsNonExpired() {
            return true;
        }
    
        @Override
        public boolean isEnabled() {
            return true;
        }
    }
    ```
    
4. Create a `UserInfoManagerConfig` class that implements the `UserDetailsService` interface, used to **retrieve user-related data, using loadUserByUsername(), and returns `UserDetails`**.
    
    ```
    @Service
    @RequiredArgsConstructor
    public class UserInfoManagerConfig implements UserDetailsService {
    
        private final UserInfoRepo userInfoRepo;
        @Override
        public UserDetails loadUserByUsername(String emailId) throws UsernameNotFoundException {
            return userInfoRepo
                    .findByEmailId(emailId)
                    .map(UserInfoConfig::new)
                    .orElseThrow(()-> new UsernameNotFoundException("UserEmail: "+emailId+" does not exist"));
        }
    }
    ```
    
    - Add the missing method findByEmailId in `userInfoRepo`
    
    ```
    @Repository
    public interface UserInfoRepo extends JpaRepository<UserInfoEntity,Long> {
        Optional<UserInfoEntity> findByEmailId(String emailId);
    }
    ```
    
5. Let's modify our Security Setting, to let it access the API using our User. Create a `SecurityConfig` file in config package.
    
    ```java
    @Configuration
    @EnableWebSecurity
    @EnableMethodSecurity
    @RequiredArgsConstructor
    public class SecurityConfig  {
    
        private final UserInfoManagerConfig userInfoManagerConfig;
    
        @Order(1)
        @Bean
        public SecurityFilterChain apiSecurityFilterChain(HttpSecurity httpSecurity) throws Exception{
            return httpSecurity
                    .securityMatcher(new AntPathRequestMatcher("/api/**"))
                    .csrf(AbstractHttpConfigurer::disable)
                    .authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
                    .userDetailsService(userInfoManagerConfig)
                    .formLogin(withDefaults())
                    .httpBasic(withDefaults())
                    .build();
        }
    
        @Order(2)
        @Bean
        public SecurityFilterChain h2ConsoleSecurityFilterChainConfig(HttpSecurity httpSecurity) throws Exception{
            return httpSecurity
                    .securityMatcher(new AntPathRequestMatcher(("/h2-console/**")))
                    .authorizeHttpRequests(auth->auth.anyRequest().permitAll())
                    .csrf(csrf -> csrf.ignoringRequestMatchers(AntPathRequestMatcher.antMatcher("/h2-console/**")))
                     // to display the h2Console in Iframe
                    .headers(headers -> headers.frameOptions(withDefaults()).disable())
                    .build();
        }
    
    }
    ```
    
6. Let's create a package called `userConfig` and add few users to the database using `CommandlineRunner`
    
    ```
    @RequiredArgsConstructor
    @Component
    @Slf4j
    public class InitialUserInfo implements CommandLineRunner {
        private final UserInfoRepo userInfoRepo;
        private final PasswordEncoder passwordEncoder;
        @Override
        public void run(String... args) throws Exception {
            UserInfoEntity manager = new UserInfoEntity();
            manager.setUserName("Manager");
            manager.setPassword(passwordEncoder.encode("password"));
            manager.setRoles("ROLE_MANAGER");
            manager.setEmailId("manager@manager.com");
    
            UserInfoEntity admin = new UserInfoEntity();
            admin.setUserName("Admin");
            admin.setPassword(passwordEncoder.encode("password"));
            admin.setRoles("ROLE_ADMIN");
            admin.setEmailId("admin@admin.com");
    
            UserInfoEntity user = new UserInfoEntity();
            user.setUserName("User");
            user.setPassword(passwordEncoder.encode("password"));
            user.setRoles("ROLE_USER");
            user.setEmailId("user@user.com");
    
            userInfoRepo.saveAll(List.of(manager,admin,user));
        }
    
    }
    ```
    
    - As we need to encrypt the password, let's add this in **securityConfig**
    
    ```
    @Bean
    PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
    }
    ```
    
7. Add the Endpoints to access in `controller` package: `DashboardController.java`
    - In simpler terms, **authentication is the process of checking if a user is who they claim to be**, while **principal is the user who has been verified**.
    
    ```
    @RestController
    @RequestMapping("/api")
    @RequiredArgsConstructor
    public class DashboardController {
    
        @PreAuthorize("hasAnyRole('ROLE_MANAGER','ROLE_ADMIN','ROLE_USER')")
        @GetMapping("/welcome-message")
        public ResponseEntity<String> getFirstWelcomeMessage(Authentication authentication){
            return ResponseEntity.ok("Welcome to the JWT Tutorial:"+authentication.getName()+"with scope:"+authentication.getAuthorities());
        }
    
        @PreAuthorize("hasRole('ROLE_MANAGER')")
        @GetMapping("/manager-message")
        public ResponseEntity<String> getManagerData(Principal principal){
            return ResponseEntity.ok("Manager::"+principal.getName());
    
        }
    
        @PreAuthorize("hasRole('ROLE_ADMIN')")
        @PostMapping("/admin-message")
        public ResponseEntity<String> getAdminData(@RequestParam("message") String message, Principal principal){
            return ResponseEntity.ok("Admin::"+principal.getName()+" has this message:"+message);
    
        }
    
    }
    ```
    
8. Test the API in PostMan
    - [http://localhost:8080/h2-console/](http://localhost:8080/h2-console/) , to see if data exist in the database
    - [http://localhost:8080/api/welcome-message](http://localhost:8080/api/welcome-message) : Accessed by all
    - [http://localhost:8080/api/manager-message](http://localhost:8080/api/manager-message) : Manager and Admin
    - [http://localhost:8080/api/admin-message](http://localhost:8080/api/admin-message): Only Admin **Params**

**Part 3: Return *Jwt Access Token* while authenticating, and add `Roles` and `Permissions`**

1. **Generating Asymmetric Keys with OpenSSL** : You have the option to create asymmetric keys (public and private keys) using OpenSSL or utilize the provided files in the repository located at resources/certs.
    
    Using OpenSSL (Optional) If you choose to generate your own keys, follow these steps:
    
    - Create a `certs` folder in the resources directory and navigate to it:
        
        ```
        cd src/main/resources/certs
        
        ```
   ```
   hheki world
   ```     
    -
