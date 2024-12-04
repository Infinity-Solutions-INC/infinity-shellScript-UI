sudo apt update
sudo apt upgrade
sudo apt install docker.io -y
sudo apt install docker-compose -y
sudo apt install npm -y
cd /etc/projeto
sudo docker-compose down
cd /etc
sudo rm -rf projeto
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
mv infinity-javaConnection-comLog/etl-infinity-1.0-SNAPSHOT-jar-with-dependencies.jar .
mv infinity-javaConnection-comLog/slack-infinity-1.0-SNAPSHOT-jar-with-dependencies.jar .
mv infinity-javaConnection-comLog/AI-infinity-1.0-SNAPSHOT-jar-with-dependencies.jar .

################################Definição Compose######################################
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  mysql-app:
    image: mysql:8.0
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
      - 80:80
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

COPY AI-infinity-1.0-SNAPSHOT-jar-with-dependencies.jar .
COPY slack-infinity-1.0-SNAPSHOT-jar-with-dependencies.jar .
COPY etl-infinity-1.0-SNAPSHOT-jar-with-dependencies.jar .
COPY script_java_etl.sh .
COPY script_java_slack.sh .
COPY script_java_ai.sh .

RUN echo "* * * * * sh /app/script_java_etl.sh" >> /etc/cron.d/app-cron
RUN echo "* * * * * sh /app/script_java_slack.sh" >> /etc/cron.d/app-cron
RUN echo "* * * * * sh /app/script_java_ai.sh" >> /etc/cron.d/app-cron


RUN chmod 664 /etc/cron.d/app-cron


RUN crontab /etc/cron.d/app-cron

CMD ["cron", "-f"]

EOF
##########################################################################
############script java para variaveis de ambiente########################
cat <<EOF > script_java_etl.sh

export AWS_ACCESS_KEY_ID=********
export AWS_SECRET_ACCESS_KEY=********
export AWS_SESSION_TOKEN=********

export DB_USER=********
export DB_PASSWORD=********

/usr/local/openjdk-21/bin/java -jar /app/etl-infinity-1.0-SNAPSHOT-jar-with-dependencies.jar

EOF
##########################################################################
############script java-slack para variaveis de ambiente########################
cat <<EOF > script_java_slack.sh

export TOKEN_ERROR=********
export TOKEN_RECOMENDACAO=********

export DB_USER=********
export DB_PASSWORD=********

/usr/local/openjdk-21/bin/java -jar /app/slack-infinity-1.0-SNAPSHOT-jar-with-dependencies.jar

EOF
##########################################################################
############script java-ai para variaveis de ambiente########################
cat <<EOF > script_java_ai.sh

export DB_USER=********
export DB_PASSWORD=********

export API_KEY=AIzaSyDtNqyQtgMPJSvGh457ZVv2rTPcglgcBWc

/usr/local/openjdk-21/bin/java -jar /app/AI-infinity-1.0-SNAPSHOT-jar-with-dependencies.jar

EOF
##########################################################################
############Definição variaveis de ambiente###############################
echo "AMBIENTE_PROCESSO=desenvolvimento
# Configurações de conexão com o banco de dados
DB_HOST=********'
DB_DATABASE='********'
DB_USER='********'
DB_PASSWORD='********'
##########################################################################
DB_PORT=3306

# Configurações do servidor de aplicação
APP_PORT=80
APP_HOST=localhost

# importante: caso sua senha contenha caracteres especiais, insira-a entre 'aspas'
" > .env.dev
########################################################################################
docker-compose up -d --build

