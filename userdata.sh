#!/bin/bash
                      #########################################################
                      ######################USer Data Config###################
                      #########################################################
                      cd /home/ec2-user/webapp
                      touch .env
                      
                      echo "DB_USER=${DB_USER}" >> .env
                      echo "DB_NAME=${DB_NAME}" >> .env
                      echo "DB_PORT=${DB_PORT}" >> .env
                      echo "APP_PORT=7070" >> .env
                      echo "DB_HOSTNAME=${DB_HOSTNAME}" >> .env
                      echo "DB_PASSWORD=${DB_PASSWORD}" >> .env
                      echo "AWS_BUCKET_NAME=${AWS_BUCKET_NAME}" >> .env


                      #mkdir -p /home/ec2-user/webapp/logs
                      #chmod 777 /home/ec2-user/webapp/logs
                      sudo systemctl start app
                      sudo systemctl status app
                      sudo systemctl enable app

                      sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                      -a fetch-config \
                      -m ec2 \
                      -c file:/home/ec2-user/webapp/config/cloudwatch-config.json \
                  -s
  