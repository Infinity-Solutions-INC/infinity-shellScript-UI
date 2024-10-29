sudo apt update
sudo apt upgrade
sudo apt install docker.io -y
sudo apt install docker-compose -y
sudo apt install npm -y
cd
mkdir /etc/projeto
cd /etc/projeto
git clone https://github.com/Infinity-Solutions-INC/institucional-infinitySolutions.git
git clone https://github.com/Infinity-Solutions-INC/infinity-solutions-DB.git
git clone https://github.com/Infinity-Solutions-INC/infinity-javaConnection-comLog.git
cd institucional-infinitySolutions
npm install
rm .env.dev .env
cd -
mv infinity-solutions-DB/script_infinitySolutions.sql .
mv infinity-javaConnection-comLog/conexao-banco-de-dados-1.0-SNAPSHOT-jar-with-dependencies.jar .

################################Definição Compose######################################
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  mysql-app:
    image: mysql:latest
    environment:
      MYSQL_ROOT_PASSWORD: 'rootpassword'
      MYSQL_DATABASE: 'infinity_solutions'
    volumes:
      - db_data:/var/lib/mysql
      - ./script_infinitySolutions.sql:/docker-entrypoint-initdb.d/script_infinitySolutions.sql
    networks:
      - app-network

  node-app:
    image: node:14
    working_dir: /app
    volumes:
      - ./institucional-infinitySolutions:/app
    env_file:
      - .env.dev
    ports:
      - 3333:3333
    command: ["npm", "start"]
    depends_on:
      - mysql-app
    networks:
      - app-network

  java-app:
    build: .
    depends_on:
      - mysql-app
    volumes:
      - ./output:/app/output
    networks:
      - app-network

volumes:
  db_data:

networks:
  app-network:
    driver: bridge

EOF
####################################################################
###################Definição dockerfile (java)######################
cat <<EOF > dockerfile
FROM openjdk:21-jdk-slim

WORKDIR /app

RUN apt update && apt install -y cron

COPY conexao-banco-de-dados-1.0-SNAPSHOT-jar-with-dependencies.jar .


RUN echo "* * * * * /usr/local/openjdk-21/bin/java -jar /app/conexao-banco-de-dados-1.0-SNAPSHOT-jar-with-dependencies.jar &&  cp arquivo.log /app/output/" > /etc/cron.d/app-cron
RUN chmod 664 /etc/cron.d/app-cron

RUN crontab /etc/cron.d/app-cron

CMD ["cron", "-f"]

EOF
##########################################################################
############Definição variaveis de ambiente###############################
echo "AMBIENTE_PROCESSO=desenvolvimento
# Configurações de conexão com o banco de dados
DB_HOST='mysql-app'
DB_DATABASE='infinity_solutions'
DB_USER='root'
DB_PASSWORD='rootpassword'
DB_PORT=3306

# Configurações do servidor de aplicação
APP_PORT=3333
APP_HOST=localhost

# importante: caso sua senha contenha caracteres especiais, insira-a entre 'aspas'
" > .env.dev
########################################################################################
docker-compose up -d --build


