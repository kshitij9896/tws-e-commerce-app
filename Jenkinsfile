// Self-contained pipeline: no shared library needed.
pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME           = 'devkshitij7/easyshop-app'
        DOCKER_MIGRATION_IMAGE_NAME = 'devkshitij7/easyshop-migration'
        DOCKER_IMAGE_TAG            = "${BUILD_NUMBER}"
        GIT_REPO                    = 'https://github.com/kshitij9896/tws-e-commerce-app.git'
        GIT_BRANCH                  = 'devkshitij'
    }

    stages {
        stage('Cleanup Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Clone Repository') {
            steps {
                git url: env.GIT_REPO, branch: env.GIT_BRANCH, credentialsId: 'github-credentials'
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build Main App Image') {
                    steps {
                        sh 'docker build -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG -t $DOCKER_IMAGE_NAME:latest -f Dockerfile .'
                    }
                }
                stage('Build Migration Image') {
                    steps {
                        sh 'docker build -t $DOCKER_MIGRATION_IMAGE_NAME:$DOCKER_IMAGE_TAG -t $DOCKER_MIGRATION_IMAGE_NAME:latest -f scripts/Dockerfile.migration .'
                    }
                }
            }
        }

        // The project has no unit tests, so run the linter inside a Node container.
        // Failures mark the build UNSTABLE instead of stopping the pipeline.
        stage('Lint') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh 'docker run --rm --user "$(id -u):$(id -g)" -e npm_config_cache=/tmp/.npm -e HOME=/tmp -v "$PWD":/app -w /app node:18-alpine sh -c "npm ci && npm run lint"'
                }
            }
        }

        // Reports HIGH/CRITICAL issues but does not fail the build (exit-code 0).
        stage('Security Scan with Trivy') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL --exit-code 0 --no-progress $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG'
                sh 'trivy image --severity HIGH,CRITICAL --exit-code 0 --no-progress $DOCKER_MIGRATION_IMAGE_NAME:$DOCKER_IMAGE_TAG'
            }
        }

        stage('Push Docker Images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials',
                                                  usernameVariable: 'DH_USER',
                                                  passwordVariable: 'DH_PASS')]) {
                    sh '''
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
                        docker push $DOCKER_IMAGE_NAME:latest
                        docker push $DOCKER_MIGRATION_IMAGE_NAME:$DOCKER_IMAGE_TAG
                        docker push $DOCKER_MIGRATION_IMAGE_NAME:latest
                        docker logout
                    '''
                }
            }
        }

        // Writes the new image tag into the manifests and pushes to YOUR branch.
        stage('Update Kubernetes Manifests') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-credentials',
                                                  usernameVariable: 'GIT_USER',
                                                  passwordVariable: 'GIT_PASS')]) {
                    sh '''
                        sed -i "s|image: ${DOCKER_IMAGE_NAME}:.*|image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}|" kubernetes/08-easyshop-deployment.yaml
                        sed -i "s|image: ${DOCKER_MIGRATION_IMAGE_NAME}:.*|image: ${DOCKER_MIGRATION_IMAGE_NAME}:${DOCKER_IMAGE_TAG}|" kubernetes/12-migration-job.yaml

                        git config user.name "Jenkins CI"
                        git config user.email "kshitijbansod47@gmail.com"
                        git add kubernetes/
                        if git diff --cached --quiet; then
                            echo "No manifest changes to commit."
                        else
                            git commit -m "Update image tags to ${DOCKER_IMAGE_TAG} [skip ci]"
                            git push "https://${GIT_USER}:${GIT_PASS}@github.com/kshitij9896/tws-e-commerce-app.git" HEAD:${GIT_BRANCH}
                        fi
                    '''
                }
            }
        }
    }

    post {
        always {
            // Keep the 20 GB Jenkins disk from filling up with old images
            sh 'docker image prune -f || true'
        }
    }
}
