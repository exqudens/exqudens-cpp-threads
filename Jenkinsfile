pipeline {
    agent any
    stages {
        stage('Clone') {
            steps {
                git(
                    credentialsId: 'github-token',
                    url: 'https://github.com/exqudens/exqudens-cpp-threads.git'
                )
            }
        }
    }
    post {
        cleanup {
            cleanWs()
        }
    }
}
