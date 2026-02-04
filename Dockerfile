# Stage 1: Build the application
FROM gradle:jdk21 AS builder

# Set working directory
WORKDIR /home/gradle/project

# Copy Gradle configuration files
COPY settings.gradle build.gradle gradle.properties gradlew VERSION ./
COPY gradle ./gradle

# Copy source code
COPY jpos ./jpos

# Build the application
# Create a dummy .git/HEAD to satisfy the build script
RUN mkdir -p .git && echo "ref: refs/heads/master" > .git/HEAD
# Grant execution permissions to gradlew
RUN sed -i 's/\r$//' gradlew
RUN chmod +x gradlew
# Downgrade to Java 21 to match the builder image
RUN sed -i 's/JavaVersion.VERSION_25/JavaVersion.VERSION_21/g' build.gradle
RUN sed -i 's/options.release = .*$/options.release = 21/' build.gradle
# We use installApp to create the distribution
RUN ./gradlew :jpos:installApp --no-daemon

# Fix line endings and permissions for startup scripts
RUN sed -i 's/\r$//' jpos/build/install/jpos/bin/q2 && \
    chmod +x jpos/build/install/jpos/bin/q2

# Stage 2: Runtime image
FROM eclipse-temurin:21-jre

# Set working directory
WORKDIR /opt/jpos

# Copy the built application from the builder stage
COPY --from=builder /home/gradle/project/jpos/build/install/jpos/ .

# Expose necessary ports
# 8080: HTTP
# 8443: HTTPS
# 9999: Q2 Remote
# 10000: Q2 Remote (Optional)
EXPOSE 8080 8443 9999

# Set the entrypoint
CMD ["bin/q2"]
