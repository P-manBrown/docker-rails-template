# syntax=docker/dockerfile:1
ARG RUBY_IMAGE_TAG
FROM ruby:${RUBY_IMAGE_TAG}

ARG PROJECT_NAME
ARG RUBYGEMS_VERSION
ARG USER_NAME
ENV TZ=Asia/Tokyo

COPY --chmod=755 /.docker/api/entrypoint.sh /usr/bin/
ENTRYPOINT ["entrypoint.sh"]

RUN adduser ${USER_NAME}
RUN chown -R ${USER_NAME} ${GEM_HOME}
USER ${USER_NAME}

WORKDIR /home/${USER_NAME}/${PROJECT_NAME}
COPY --chown=${USER_NAME} Gemfile* /home/${USER_NAME}/${PROJECT_NAME}/
RUN --mount=type=secret,uid=1000,id=github-pkg-cred,required \
--mount=type=cache,uid=1000,target=/home/${USER_NAME}/.cache/bundle <<-EOF
	set -eux
	gem update --system ${RUBYGEMS_VERSION}
	export BUNDLE_RUBYGEMS__PKG__GITHUB__COM=$(cat /run/secrets/github-pkg-cred)
	GEM_HOME=/home/${USER_NAME}/.cache/bundle bundle install
	cp -aRT /home/${USER_NAME}/.cache/bundle ${GEM_HOME}
EOF

RUN mkdir -p /home/${USER_NAME}/${PROJECT_NAME}/tmp/sockets

EXPOSE 3000

CMD ["bundle", "exec", "pumactl", "start"]
