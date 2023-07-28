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
        stage('Configure') {
            steps {
                script {
                    def presets = bat(script: 'cmake --list-presets', returnStdout: true)
                        .split('Available configure presets:')[1]
                        .trim()
                        .tokenize('\n')
                        .collect { it.trim().replace('"', '') }
                    for (preset in presets) {
                        def script = [
                            'cmake',
                            '--preset',
                            '"' + preset + '"'
                        ].join(' ')
                        bat(script: script)
                    }
                }
            }
        }
        stage('Build') {
            steps {
                script {
                    def presets = bat(script: 'cmake --list-presets', returnStdout: true)
                        .split('Available configure presets:')[1]
                        .trim()
                        .tokenize('\n')
                        .collect { it.trim().replace('"', '') }
                    for (preset in presets) {
                        def script = [
                            'cmake',
                            '--build',
                            '--preset',
                            '"' + preset + '"',
                            '--target',
                            'conan-export'
                        ].join(' ')
                        bat(script: script)
                    }
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
