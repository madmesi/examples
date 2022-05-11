## known error when you try to connect to kafka from a client (example: conduktor client):
_"The broker [...] is reachable but Kafka can't connect. Ensure you have access to the advertised listeners of the the brokers and the proper authorization"

How to fix:
inside the docker-compose.yml file
`advertised.listeners=PLAINTEXT://1.2.3.4:9092`
Replace 1.2.3.4 with your server ip address.
Source: https://stackoverflow.com/a/65103445/8357181
