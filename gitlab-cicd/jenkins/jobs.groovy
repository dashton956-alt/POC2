// POC2 Jenkins Job DSL Script
// This script creates Jenkins jobs for the POC2 Intent-Based Networking platform

// Main POC2 Pipeline Job
pipelineJob('poc2-main-pipeline') {
    displayName('POC2 Main Pipeline')
    description('Main CI/CD pipeline for POC2 Intent-Based Networking platform')
    
    parameters {
        choiceParam('DEPLOYMENT_TYPE', [
            'full-stack',
            'netbox-only',
            'n8n-workflows', 
            'diode-sync',
            'jenkins-only',
            'health-check',
            'rollback'
        ], 'Select deployment scope')
        
        choiceParam('DEPLOYMENT_STRATEGY', [
            'rolling',
            'blue-green',
            'recreate'
        ], 'Choose deployment strategy')
        
        choiceParam('ENVIRONMENT', [
            'development',
            'staging',
            'production'
        ], 'Target environment')
        
        booleanParam('SKIP_TESTS', false, 'Skip test execution (not recommended for production)')
        booleanParam('CREATE_BACKUP', true, 'Create backup before deployment')
        booleanParam('SKIP_SECURITY_SCAN', false, 'Skip security vulnerability scanning')
        stringParam('CUSTOM_TAG', '', 'Custom Docker image tag (optional)')
    }
    
    properties {
        buildDiscarder {
            strategy {
                logRotator {
                    numToKeepStr('30')
                    artifactNumToKeepStr('10')
                    daysToKeepStr('90')
                }
            }
        }
        
        pipelineTriggers {
            triggers {
                // GitHub webhook trigger
                githubPush()
                
                // Scheduled health checks
                cron {
                    spec('H 2 * * *') // Daily at 2 AM
                }
                
                // Poll SCM
                scm('H/5 * * * *') // Every 5 minutes
            }
        }
    }
    
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/dashton956-alt/POC2.git')
                        credentials('github-credentials')
                    }
                    branch('*/main')
                }
            }
            scriptPath('gitlab-cicd/jenkins/Jenkinsfile-Modern')
            lightweight(true)
        }
    }
}

// NetBox Specific Pipeline
pipelineJob('poc2-netbox-pipeline') {
    displayName('POC2 NetBox Pipeline')
    description('NetBox DCIM/IPAM deployment pipeline')
    
    parameters {
        choiceParam('ACTION', [
            'deploy',
            'backup',
            'restore',
            'migrate',
            'health-check'
        ], 'NetBox action to perform')
        
        booleanParam('SKIP_MIGRATION', false, 'Skip database migrations')
        booleanParam('LOAD_FIXTURES', false, 'Load sample data fixtures')
    }
    
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    
                    stages {
                        stage('NetBox Deployment') {
                            steps {
                                script {
                                    sh """
                                        cd netbox-docker
                                        ./scripts/pipeline-orchestrator.sh deploy-netbox
                                    """
                                }
                            }
                        }
                        
                        stage('NetBox Health Check') {
                            steps {
                                script {
                                    sh 'curl -f http://localhost:8000/api/status/'
                                }
                            }
                        }
                    }
                    
                    post {
                        always {
                            archiveArtifacts artifacts: 'artifacts/**/*', allowEmptyArchive: true
                        }
                    }
                }
            ''')
        }
    }
}

// n8n Workflow Pipeline
pipelineJob('poc2-n8n-pipeline') {
    displayName('POC2 n8n Workflow Pipeline')
    description('n8n workflow automation deployment pipeline')
    
    parameters {
        choiceParam('ACTION', [
            'deploy-workflows',
            'validate-workflows', 
            'backup-workflows',
            'test-workflows'
        ], 'n8n action to perform')
        
        stringParam('WORKFLOW_FILTER', '*', 'Workflow name pattern to deploy (supports wildcards)')
    }
    
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    
                    stages {
                        stage('Validate Workflows') {
                            steps {
                                script {
                                    sh """
                                        cd n8n
                                        find workflows -name "*.json" -exec jq . {} \\;
                                    """
                                }
                            }
                        }
                        
                        stage('Deploy n8n') {
                            steps {
                                script {
                                    sh './scripts/pipeline-orchestrator.sh deploy-n8n'
                                }
                            }
                        }
                    }
                }
            ''')
        }
    }
}

// Diode Sync Pipeline
pipelineJob('poc2-diode-pipeline') {
    displayName('POC2 Diode Sync Pipeline')
    description('Diode data synchronization service pipeline')
    
    parameters {
        choiceParam('SYNC_DIRECTION', [
            'netbox-to-external',
            'external-to-netbox',
            'bidirectional'
        ], 'Data synchronization direction')
        
        booleanParam('DRY_RUN', true, 'Perform dry run without making changes')
    }
    
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    
                    stages {
                        stage('Deploy Diode') {
                            steps {
                                script {
                                    sh './scripts/pipeline-orchestrator.sh deploy-diode'
                                }
                            }
                        }
                        
                        stage('Test Sync') {
                            steps {
                                script {
                                    sh 'curl -f http://localhost:8080/health'
                                }
                            }
                        }
                    }
                }
            ''')
        }
    }
}

// Health Check Pipeline  
pipelineJob('poc2-health-check') {
    displayName('POC2 Health Check')
    description('Comprehensive health check for all POC2 services')
    
    triggers {
        cron('H/15 * * * *') // Every 15 minutes
    }
    
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    
                    stages {
                        stage('Health Check') {
                            parallel {
                                stage('NetBox Health') {
                                    steps {
                                        script {
                                            def response = sh(
                                                script: 'curl -s -f http://localhost:8000/api/status/',
                                                returnStdout: true
                                            ).trim()
                                            echo "NetBox Status: ${response}"
                                        }
                                    }
                                }
                                
                                stage('n8n Health') {
                                    steps {
                                        script {
                                            sh 'curl -f http://localhost:5678/healthz'
                                            echo "n8n is healthy"
                                        }
                                    }
                                }
                                
                                stage('Diode Health') {
                                    steps {
                                        script {
                                            sh 'curl -f http://localhost:8080/health'
                                            echo "Diode is healthy"
                                        }
                                    }
                                }
                                
                                stage('Docker Health') {
                                    steps {
                                        script {
                                            sh 'docker ps --format "table {{.Names}}\\t{{.Status}}"'
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    post {
                        failure {
                            emailext(
                                subject: 'POC2 Health Check Failed',
                                body: 'One or more POC2 services are unhealthy. Please check the Jenkins console output.',
                                to: '${DEFAULT_RECIPIENTS}'
                            )
                        }
                    }
                }
            ''')
        }
    }
}

// Backup Pipeline
pipelineJob('poc2-backup-pipeline') {
    displayName('POC2 Backup Pipeline')
    description('Create backups of all POC2 services and data')
    
    parameters {
        choiceParam('BACKUP_TYPE', [
            'full',
            'config-only',
            'data-only'
        ], 'Type of backup to create')
        
        booleanParam('COMPRESS_BACKUP', true, 'Compress backup files')
        stringParam('RETENTION_DAYS', '30', 'Number of days to retain backups')
    }
    
    triggers {
        cron('H 1 * * *') // Daily at 1 AM
    }
    
    definition {
        cps {
            script('''
                pipeline {
                    agent any
                    
                    stages {
                        stage('Create Backup') {
                            steps {
                                script {
                                    sh './scripts/pipeline-orchestrator.sh backup'
                                }
                            }
                        }
                        
                        stage('Cleanup Old Backups') {
                            steps {
                                script {
                                    sh """
                                        find artifacts/backups -name "*.tar.gz" -mtime +${params.RETENTION_DAYS} -delete
                                        echo "Cleaned up backups older than ${params.RETENTION_DAYS} days"
                                    """
                                }
                            }
                        }
                    }
                    
                    post {
                        success {
                            archiveArtifacts artifacts: 'artifacts/backups/*.tar.gz', allowEmptyArchive: true
                        }
                    }
                }
            ''')
        }
    }
}

// Multi-branch Pipeline for Development
multibranchPipelineJob('poc2-multibranch') {
    displayName('POC2 Multi-branch Pipeline')
    description('Multi-branch pipeline for POC2 development and feature branches')
    
    branchSources {
        git {
            id('poc2-git')
            remote('https://github.com/dashton956-alt/POC2.git')
            credentialsId('github-credentials')
            
            traits {
                gitBranchDiscovery()
                gitTagDiscovery()
                cleanBeforeCheckoutTrait()
            }
        }
    }
    
    factory {
        workflowBranchProjectFactory {
            scriptPath('gitlab-cicd/jenkins/Jenkinsfile-Modern')
        }
    }
    
    triggers {
        periodic(5) // Check for new branches every 5 minutes
    }
    
    properties {
        buildDiscarder {
            strategy {
                logRotator {
                    numToKeepStr('10')
                    artifactNumToKeepStr('5')
                }
            }
        }
    }
}

// Folder for organizing jobs
folder('POC2') {
    displayName('POC2 Intent-Based Networking')
    description('All jobs related to POC2 platform')
}

// Move jobs into folder
[
    'poc2-main-pipeline',
    'poc2-netbox-pipeline', 
    'poc2-n8n-pipeline',
    'poc2-diode-pipeline',
    'poc2-health-check',
    'poc2-backup-pipeline',
    'poc2-multibranch'
].each { jobName ->
    queue("POC2/${jobName}")
}
