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
        stage('Build') {
            steps {
                script {
                    def s = bat(script: 'dir', returnStdout: true)
                    echo("---")
                    echo("s: '${s}'")
                    echo("---")
                }
            }
        }
    }
    post {
        cleanup {
            cleanWs()
        }
    }
}
