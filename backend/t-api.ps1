warning: in the working copy of 'pom.xml', LF will be replaced by CRLF the next time Git touches it
[1mdiff --git a/pom.xml b/pom.xml[m
[1mindex 74f2335..39e1676 100644[m
[1m--- a/pom.xml[m
[1m+++ b/pom.xml[m
[36m@@ -82,15 +82,26 @@[m
             <artifactId>spring-boot-starter-test</artifactId>[m
             <scope>test</scope>[m
         </dependency>[m
[32m+[m
[32m+[m[32m        <!-- H2 Database for Testing -->[m
         <dependency>[m
[31m-            <groupId>org.springframework.boot</groupId>[m
[31m-            <artifactId>spring-boot-devtools</artifactId>[m
[32m+[m[32m            <groupId>com.h2database</groupId>[m
[32m+[m[32m            <artifactId>h2</artifactId>[m
             <scope>runtime</scope>[m
         </dependency>[m
[32m+[m
[32m+[m[32m        <!-- Spring Boot Actuator (Monitoring) -->[m
         <dependency>[m
             <groupId>org.springframework.boot</groupId>[m
             <artifactId>spring-boot-starter-actuator</artifactId>[m
         </dependency>[m
[32m+[m
[32m+[m[32m        <!-- SpringDoc OpenAPI (Swagger UI) -->[m
[32m+[m[32m        <dependency>[m
[32m+[m[32m            <groupId>org.springdoc</groupId>[m
[32m+[m[32m            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>[m
[32m+[m[32m            <version>2.6.0</version>[m
[32m+[m[32m        </dependency>[m
     </dependencies>[m
 [m
     <build>[m
