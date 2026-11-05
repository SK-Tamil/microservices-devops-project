
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    environment {
        AWS_REGION   = 'us-east-1'
        AWS_ACCOUNT  = '165328639795'
        ECR_REGISTRY = '165328639795.dkr.ecr.us-east-1.amazonaws.com'

        DEPLOY_DIR   = '/opt/microservices-app'
        COMPOSE_NAME = 'microservices-prod'
    }

    stages {

        // 1. CHECKOUT SOURCE CODE
        stage('1. Source Checkout') {
            steps {
                checkout scm

                script {
                    def commit = sh(
                        script: 'git rev-parse --short=8 HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${commit}"

                    currentBuild.description =
                        "Release: ${env.IMAGE_TAG}"
                }

                echo "Building release: ${IMAGE_TAG}"
            }
        }

        // 2. CONFIGURATION VALIDATION
        stage('2. Configuration Validation') {
            steps {
                sh '''
                    set -eu

                    for SERVICE in user-service product-service order-service
                    do
                        test -f "$SERVICE/Dockerfile"
                    done

                    test -f docker-compose.yml
                    test -f docker-compose.deploy.yml
                    test -f nginx/nginx.conf
                    test -f frontend/index.html

                    docker --version
                    docker compose version
                    aws --version

                    docker compose -f docker-compose.yml config -q

                    export IMAGE_TAG="$IMAGE_TAG"
                    export ECR_REGISTRY="$ECR_REGISTRY"

                    docker compose \
                      -f docker-compose.deploy.yml config -q

                    echo "Configuration validation passed."
                '''
            }
        }

        // 3. APPLICATION TESTS
        stage('3. Application Tests') {
            steps {
                sh '''
                    set -eu

                    for SERVICE in user-service product-service order-service
                    do
                        echo "Validating $SERVICE"

                        docker run --rm \
                          -v "$WORKSPACE/$SERVICE:/src" \
                          -w /src \
                          python:3.12-slim \
                          sh -c '
                            set -e

                            python -m compileall -q .

                            if find . -type f \
                              \\( -name "test_*.py" -o -name "*_test.py" \\) \
                              | grep -q .; then

                                if [ -f requirements.txt ]; then
                                    pip install --no-cache-dir -r requirements.txt
                                fi

                                pip install --no-cache-dir pytest
                                pytest -q
                            else
                                echo "No automated test files found."
                                echo "Python syntax validation passed."
                            fi
                          '
                    done

                    echo "Application validation completed."
                '''
            }
        }

        // 4. BUILD DOCKER IMAGES
        stage('4. Docker Build and Image Tagging') {
            steps {
                sh '''
                    set -eu

                    for SERVICE in user-service product-service order-service
                    do
                        IMAGE="$ECR_REGISTRY/$SERVICE:$IMAGE_TAG"

                        echo "Building $IMAGE"

                        docker build --pull \
                          -t "$IMAGE" \
                          "./$SERVICE"

                        docker image inspect "$IMAGE" >/dev/null
                    done

                    echo "All Docker images built successfully."
                '''
            }
        }

        // 5. AUTHENTICATE WITH ECR
        stage('5. Secure ECR Authentication') {
            steps {
                sh '''
                    set -eu

                    echo "Checking EC2 IAM role..."

                    aws sts get-caller-identity

                    echo "Logging in to Amazon ECR..."

                    aws ecr get-login-password \
                      --region "$AWS_REGION" |
                    docker login \
                      --username AWS \
                      --password-stdin "$ECR_REGISTRY"

                    echo "ECR authentication successful."
                '''
            }
        }

        // 6. PUSH IMAGES TO ECR
        stage('6. Push Images to ECR') {
            steps {
                sh '''
                    set -eu

                    for SERVICE in user-service product-service order-service
                    do
                        IMAGE="$ECR_REGISTRY/$SERVICE:$IMAGE_TAG"

                        echo "Pushing $IMAGE"

                        docker push "$IMAGE"
                    done

                    echo "All images pushed to ECR."
                '''
            }
        }

        // 7. PREPARE VERSIONED RELEASE
        stage('7. Prepare Deployment Release') {
            steps {
                sh '''
                    set -eu

                    RELEASE_DIR="$DEPLOY_DIR/releases/$IMAGE_TAG"

                    mkdir -p "$RELEASE_DIR/frontend"
                    mkdir -p "$RELEASE_DIR/nginx"

                    cp -a frontend/. "$RELEASE_DIR/frontend/"
                    cp -a nginx/. "$RELEASE_DIR/nginx/"

                    cp docker-compose.deploy.yml \
                      "$RELEASE_DIR/docker-compose.deploy.yml"

                    test -f "$RELEASE_DIR/frontend/index.html"
                    test -f "$RELEASE_DIR/nginx/nginx.conf"

                    export IMAGE_TAG="$IMAGE_TAG"
                    export ECR_REGISTRY="$ECR_REGISTRY"

                    docker compose \
                      --project-directory "$RELEASE_DIR" \
                      -f "$RELEASE_DIR/docker-compose.deploy.yml" \
                      config -q

                    echo "Release prepared: $RELEASE_DIR"
                '''
            }
        }

        // 8. DEPLOYMENT + HEALTH CHECK + AUTOMATIC ROLLBACK
        stage('8. Deploy and Automatic Rollback') {
            steps {
                script {

                    env.PREVIOUS_TAG = sh(
                        script: '''
                            if [ -s "$DEPLOY_DIR/.last_successful_tag" ]; then
                                cat "$DEPLOY_DIR/.last_successful_tag"
                            fi
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Previous successful release: ${env.PREVIOUS_TAG ?: 'None (first deployment)'}"

                    sh '''
                        set -eu

                        RELEASE_DIR="$DEPLOY_DIR/releases/$IMAGE_TAG"

                        # Health check all three services through Nginx
                        health_check() {
                            echo "Checking application health..."

                            for ATTEMPT in $(seq 1 24)
                            do
                                if curl -fsS http://127.0.0.1/health/user >/dev/null &&
                                   curl -fsS http://127.0.0.1/health/product >/dev/null &&
                                   curl -fsS http://127.0.0.1/health/order >/dev/null
                                then
                                    echo "All services are healthy."
                                    return 0
                                fi

                                echo "Health check attempt $ATTEMPT/24 failed."
                                sleep 5
                            done

                            echo "Application health check failed."
                            return 1
                        }

                        # Deploy or restore a particular release
                        deploy_release() {
                            TAG="$1"
                            DIR="$DEPLOY_DIR/releases/$TAG"

                            if [ ! -f "$DIR/docker-compose.deploy.yml" ]; then
                                echo "Release files not found: $DIR"
                                return 1
                            fi

                            export IMAGE_TAG="$TAG"
                            export ECR_REGISTRY="$ECR_REGISTRY"

                            docker compose \
                              -p "$COMPOSE_NAME" \
                              --project-directory "$DIR" \
                              -f "$DIR/docker-compose.deploy.yml" \
                              pull || return 1

                            docker compose \
                              -p "$COMPOSE_NAME" \
                              --project-directory "$DIR" \
                              -f "$DIR/docker-compose.deploy.yml" \
                              up -d --remove-orphans || return 1

                            health_check
                        }

                        echo "Deploying new release: $IMAGE_TAG"

                        if deploy_release "$IMAGE_TAG"; then

                            echo "$IMAGE_TAG" > \
                              "$DEPLOY_DIR/.last_successful_tag.tmp"

                            mv \
                              "$DEPLOY_DIR/.last_successful_tag.tmp" \
                              "$DEPLOY_DIR/.last_successful_tag"

                            echo "NEW RELEASE DEPLOYED SUCCESSFULLY."

                        else

                            echo "NEW DEPLOYMENT FAILED."

                            if [ -n "$PREVIOUS_TAG" ]; then

                                echo "Starting automatic rollback..."
                                echo "Restoring release: $PREVIOUS_TAG"

                                if deploy_release "$PREVIOUS_TAG"; then
                                    echo "ROLLBACK SUCCESSFUL."
                                    echo "Previous application version restored."
                                else
                                    echo "CRITICAL: AUTOMATIC ROLLBACK FAILED."
                                    exit 2
                                fi

                            else

                                echo "No previous successful release exists."
                                echo "This is the first deployment; rollback is unavailable."

                            fi

                            exit 1
                        fi
                    '''
                }
            }
        }
    }

    // PIPELINE RESULT AND LOGS
    post {

        success {
            echo '''
            =========================================
            CI/CD PIPELINE SUCCESSFUL
            =========================================
            Docker images built and pushed.
            Application deployed successfully.
            Health checks passed.
            '''
        }

        failure {
            echo '''
            =========================================
            CI/CD PIPELINE FAILED
            =========================================
            Check the stage logs.
            Automatic rollback was attempted if a
            previous successful release was available.
            =========================================
            '''
        }

        always {
            sh(
                returnStatus: true,
                script: '''
                    echo "Docker container status:"
                    docker ps -a

                    echo "Deployment logs:"

                    if [ -f "$DEPLOY_DIR/.last_successful_tag" ]; then
                        TAG=$(cat "$DEPLOY_DIR/.last_successful_tag")
                        DIR="$DEPLOY_DIR/releases/$TAG"

                        if [ -f "$DIR/docker-compose.deploy.yml" ]; then
                            docker compose \
                              -p "$COMPOSE_NAME" \
                              --project-directory "$DIR" \
                              -f "$DIR/docker-compose.deploy.yml" \
                              logs --tail=100 || true
                        fi
                    fi
                '''
            )
        }
    }
}
