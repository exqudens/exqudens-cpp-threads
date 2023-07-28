pipeline {
    stages {
        stage('Clone') {
            steps {
                script {
                    git(
                        credentialsId: 'github-token',
                        url: 'https://github.com/exqudens/exqudens-cpp-threads.git'
                    )
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
