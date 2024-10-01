# Detection-changing-file-in-VM
Here's how you can set up a system that detects file alterations in Jenkins and applies those changes to a VM, while also copying new files to another VM through a remote server:

1. Activate Jenkins Container

   docker run --name myjenkins2 --privileged -p 8080:8080 -v $(pwd)/appjardir:/var/jenkins_home/appjar jenkins/jenkins:lts-jdk17

  ![image](https://github.com/user-attachments/assets/a2005470-f3ce-4c9d-8a9e-05fcc7c22e8a)

2. Activate Ngrok

   ngork http http://localhost:[포트번호]

   ![image](https://github.com/user-attachments/assets/97f2f828-21c8-451d-bde8-6a71df547160)

  🧰 Troubleshooting about Ngrok
  
    If there is a problem about port, you may visit website (ngrok agents) And you disable port what you will use. After doing, reconnect.
    
  ![image](https://github.com/user-attachments/assets/e9f74b69-9c53-430d-892d-506bea832775)

  3. Setting for connecting between Ngrok and Github
     1) Jenkins Setting
        - Check "Github hook trigger for GITScm polling"
          ![image](https://github.com/user-attachments/assets/6fba1711-973a-4f7a-9144-9a67c6e473f9)
        - Insert you Github Repository URL
          ![image](https://github.com/user-attachments/assets/e97d7499-a999-4085-8d30-4a70ff36e556)
      2) Github Setting
         - Check your Github Branch
           ![image](https://github.com/user-attachments/assets/1a203204-56e1-487c-95a1-ffe2de2ba218)
         - Insert Ngork URL with "/github-webhook/"
           ![image](https://github.com/user-attachments/assets/e6080130-f11a-4e1c-b4ae-dbb9119849d1)
      3) Complete
            ![image](https://github.com/user-attachments/assets/f2aa966a-88d2-4dda-9873-36cd21dd5e7d)

    4. Jenkins through Script
      1) Through Script, It makes possible clone, build and copy file to VM
          '''bash
          pipeline {
	agent any

	stages {
		stage('Clone Repository') {
			steps {
				git branch: 'main', url: 'https://github.com/bigkhk/fisatest.git'
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
  '''

  - If you commit contents in Github, Jenkins will detect it automatically and reflect into your VM
    ![image](https://github.com/user-attachments/assets/f7e32f2f-885a-405b-91d6-8996792f4dd4)
    ![image](https://github.com/user-attachments/assets/224fbd86-dd32-43ef-9bc0-bd840d132eae)
    ![image](https://github.com/user-attachments/assets/2904b03c-657e-43e5-a4b5-4f89512a4ded)
