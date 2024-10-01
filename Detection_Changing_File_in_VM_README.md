
# 🚀 Detection-Changing-File-in-VM

This guide explains how to set up a system that detects file alterations in Jenkins, applies those changes to a VM, and copies new files to another VM through a remote server using SSH keys.

---

## 🛠 1. Activate Jenkins Container

To start, you need to activate Jenkins in a container. Run the following command:

```bash
docker run --name myjenkins2 --privileged -p 8080:8080 -v $(pwd)/appjardir:/var/jenkins_home/appjar jenkins/jenkins:lts-jdk17
```

This command starts Jenkins and mounts the `appjardir` directory in the Jenkins home directory to manage the files.

---

## 🌐 2. Activate Ngrok

After setting up Jenkins, you'll need to activate Ngrok to expose Jenkins to the web. Use the following command:

```bash
ngrok http http://localhost:[your_port_number]
```

If you encounter issues with the port, visit the Ngrok agents website, disable the port you want to use, and reconnect.

---

## 🔗 3. Configure Jenkins and GitHub Integration

To automate the deployment process, you need to link Jenkins with GitHub.

### 1) Jenkins Settings:
- Enable "GitHub hook trigger for GITScm polling" in Jenkins settings.
- Add your GitHub repository URL.

### 2) GitHub Settings:
- Ensure your GitHub branch is correctly set.
- Add your Ngrok URL followed by `/github-webhook/` in the GitHub webhook settings.

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

Once you commit your changes to GitHub, Jenkins will automatically detect and reflect the changes into your VM.

---

## 🔑 5. Set Up SSH Key (Passwordless Authentication)

To securely copy files to another VM, you need to set up SSH key-based authentication.

### 1) Generate SSH Key:
Run the following command to generate a 4096-bit RSA SSH key:

```bash
ssh-keygen -t rsa -b 4096
```

### 2) Copy SSH Key to the Target VM:
Copy the generated SSH key to the remote VM (10.0.2.19):

```bash
ssh-copy-id username@10.0.2.19
```

### 3) Log into the Remote VM:
Ensure you can log into the remote VM without a password:

```bash
ssh username@10.0.2.19
```

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

This script monitors for any changes to the JAR file and automatically transfers it to the remote server at `10.0.2.19`.

---

## 🎉 7. Complete Setup

With this setup, Jenkins will automatically detect changes from GitHub, build the project, and deploy the JAR file to your VM. The JAR file will also be copied to another VM through a secure SSH connection.

Feel free to customize the pipeline or script as needed for your environment!
