#! /bin/sh

# Creating roup named Testgroup
./client.test POST / -p name-of-group:testgroup -f properties:text/xml:dev/properties-example.xml -f query-input:text/xml:dev/query-input-example.xml -f query-output:text/xml:dev/query-output-example.xml -f invoke-input:text/xml:dev/invoke-input-example.xml -f invoke-output:text/xml:dev/invoke-output-example.xml  

# Creating subgroup named testsubgroup
./client.test POST /testgroup -p name-of-subgroup:testsubgroup

# Creating service named testservice
./client.test POST /testgroup/testsubgroup -p name-of-service:testservice -f details-of-service:text/xml:dev/service-details-example.xml 

# Updating group
./client.test PUT /testgroup -p name-of-group:testgroup2 -f properties:text/xml:dev/properties-example.xml -f query-input:text/xml:dev/query-input-example.xml -f query-output:text/xml:dev/query-output-example.xml -f invoke-input:text/xml:dev/invoke-input-example.xml -f invoke-output:text/xml:dev/invoke-output-example.xml  

# Update subgroup
 ./client.test PUT /testgroup2/testsubgroup -p name-of-subgroup:testsubgroup2

# Update service
./client.test PUT /testgroup2/testsubgroup2/testservice -p name-of-service:testservice2 -f details-of-service:text/xml:dev/service-details-example.xml     *

# Read group
./client.test GET / 

# Read subgroup
./client.test GET /testgroup2

# Reads ervices
./client.test GET /testgroup2/testsubgroup2

# Reads ervice details
./client.test GET /testgroup2/testsubgroup2/testervice2

# Delete service:
./client.test DELETE /testgroup2/testsubgroup2/testervice2

# Delete subgroup:
./client.test DELETE /testgroup2/testsubgroup2

# Delete group:
./client.test DELETE /testgroup2

