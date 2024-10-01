
# 🚀 Detection-Changing-File-in-VM

## 🛠 1. Activate Jenkins Container

To start, you need to activate Jenkins in a container. Run the following command:

```bash
docker run --name myjenkins2 --privileged -p 8080:8080 -v $(pwd)/appjardir:/var/jenkins_home/appjar jenkins/jenkins:lts-jdk17
```
![image](https://github.com/user-attachments/assets/a2005470-f3ce-4c9d-8a9e-05fcc7c22e8a)
This command starts Jenkins and mounts the `appjardir` directory in the Jenkins home directory to manage the files.

---

## 🌐 2. Activate Ngrok

After setting up Jenkins, you'll need to activate Ngrok to expose Jenkins to the web. Use the following command:

```bash
ngrok http http://localhost:[your_port_number]
```
![image](https://github.com/user-attachments/assets/97f2f828-21c8-451d-bde8-6a71df547160)
If you encounter issues with the port, visit the Ngrok agents website, disable the port you want to use, and reconnect.

### 🧰 Troubleshooting about Ngrok
  
If there is a problem about port, you may visit website (ngrok agents) And you disable port what you will use. After doing, reconnect.
    
![image](https://github.com/user-attachments/assets/e9f74b69-9c53-430d-892d-506bea832775)

---

## 🔗 3. Configure Jenkins and GitHub Integration

To automate the deployment process, you need to link Jenkins with GitHub.

### 1) Jenkins Settings:
- Enable "GitHub hook trigger for GITScm polling" in Jenkins settings.
![image](https://github.com/user-attachments/assets/6fba1711-973a-4f7a-9144-9a67c6e473f9)
- Add your GitHub repository URL.
![image](https://github.com/user-attachments/assets/e97d7499-a999-4085-8d30-4a70ff36e556)

### 2) GitHub Settings:
- Ensure your GitHub branch is correctly set.
![image](https://github.com/user-attachments/assets/1a203204-56e1-487c-95a1-ffe2de2ba218)
- Add your Ngrok URL followed by `/github-webhook/` in the GitHub webhook settings.
![image](https://github.com/user-attachments/assets/e6080130-f11a-4e1c-b4ae-dbb9119849d1)

![image](https://github.com/user-attachments/assets/f2aa966a-88d2-4dda-9873-36cd21dd5e7d)
Once configured, Jenkins will detect any changes pushed to your GitHub repository and trigger the build process automatically.

---

## 📝 4. Jenkins Pipeline Script

Use the following Jenkins pipeline script to clone, build, and copy files to the VM:

```bash
pipeline {
    agent any

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/your-repo/your-project.git'
            }
        }
        stage('Build') {
            steps {
                dir('./SpringApp') {
                    sh 'chmod +x gradlew'
                    sh './gradlew clean build -x test'
                    sh 'echo $WORKSPACE'
                }
            }
        }
        stage('Copy jar') {
            steps {
                script {
                    def jarFile = 'SpringApp/build/libs/SpringApp-0.0.1-SNAPSHOT.jar'
                    sh "cp ${jarFile} /var/jenkins_home/appjar/"
                }
            }
        }
    }
}
```
![image](https://github.com/user-attachments/assets/f7e32f2f-885a-405b-91d6-8996792f4dd4)
![image](https://github.com/user-attachments/assets/224fbd86-dd32-43ef-9bc0-bd840d132eae)
![image](https://github.com/user-attachments/assets/2904b03c-657e-43e5-a4b5-4f89512a4ded)

Once you commit your changes to GitHub, Jenkins will automatically detect and reflect the changes into your VM.

---

## 🔑 5. Set Up SSH Key (Passwordless Authentication)

To securely copy files to another VM, you need to set up SSH key-based authentication.

### 1) Generate SSH Key:
Run the following command to generate a 4096-bit RSA SSH key:

```bash
ssh-keygen -t rsa -b 4096
```
![image](https://github.com/user-attachments/assets/e6553af7-52ea-4135-808d-16a01fe3234f)
![image](https://github.com/user-attachments/assets/d6a04e4b-9b83-4cd6-86f9-5fafb0183f1b)

### 2) Copy SSH Key to the Target VM:
Copy the generated SSH key to the remote VM (10.0.2.19):

```bash
ssh-copy-id username@10.0.2.19
```
![image](https://github.com/user-attachments/assets/1854698d-e8a2-4f53-aecc-6e997d14202f)

### 3) Log into the Remote VM:
Ensure you can log into the remote VM without a password:

```bash
ssh username@10.0.2.19
```
![image](https://github.com/user-attachments/assets/fb27a5d2-ea5a-4e92-9399-d5023e540f14)
![image](https://github.com/user-attachments/assets/d171895e-7ea1-4f04-81b2-6fcad556fd96)

---

## 📂 6. Automate File Migration with Shell Script

To automate the process of detecting file changes and copying them to the remote VM, use the following shell script:

```bash
#!/bin/bash

# JAR file path
JAR_FILE="./SpringApp-0.0.1-SNAPSHOT.jar"

# Script to run after file change
SH_FILE="./autorunning.sh"

# Cooldown time to prevent duplicate execution (e.g., 10 seconds)
COOLDOWN=10
LAST_RUN=0

# Monitor file changes and run the script
inotifywait -m -e close_write "$JAR_FILE" |
while read -r directory events filename; do
    CURRENT_TIME=$(date +%s)

    if (( CURRENT_TIME - LAST_RUN > COOLDOWN )); then
        echo "$(date): $filename was modified."

        # Run the script
        bash "$SH_FILE"

        # Update last run time
        LAST_RUN=$CURRENT_TIME

        # Copy file to the remote server
        scp "/home/username/appjardir/SpringApp-0.0.1-SNAPSHOT.jar" "username@10.0.2.19:/home/username/appjardir2"
        if [ $? -eq 0 ]; then
            echo "$(date): File successfully copied to the remote server."
        else
            echo "$(date): File transfer failed."
        fi
    else
        echo "$(date): Cooldown in progress. Not executing."
    fi
done
```

```bash
scp "/home/username/appjardir/SpringApp-0.0.1-SNAPSHOT.jar" "username@10.0.2.19:/home/username/appjardir2"
```

![image](https://github.com/user-attachments/assets/f7e13efb-c9cd-4b79-8c8d-e16606c239c5)
![image](https://github.com/user-attachments/assets/954977ee-969a-4da4-a58d-4d33e8cc1603)

This script monitors for any changes to the JAR file and automatically transfers it to the remote server at `10.0.2.19`.

---

## 🎉 7. Complete Setup

With this setup, Jenkins will automatically detect changes from GitHub, build the project, and deploy the JAR file to your VM. The JAR file will also be copied to another VM through a secure SSH connection.

Feel free to customize the pipeline or script as needed for your environment!
