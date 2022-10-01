# syntax=docker/dockerfile:1
ARG RUBY_IMAGE_TAG
FROM ruby:${RUBY_IMAGE_TAG}

ARG PROJECT_NAME
ARG RUBYGEMS_VERSION
ARG USER_NAME=ruby
ENV TZ=Asia/Tokyo

RUN <<-EOF
	set -e
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	| dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
	| tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	apt update
	apt install gh -y
EOF

RUN adduser ${USER_NAME}
COPY --chown=${USER_NAME} Gemfile* /${PROJECT_NAME}/
WORKDIR /${PROJECT_NAME}
RUN	--mount=type=secret,id=github-pkg-cred,required <<-EOF
	set -eu
	gem update --system ${RUBYGEMS_VERSION}
	export BUNDLE_RUBYGEMS__PKG__GITHUB__COM=$(cat /run/secrets/github-pkg-cred)
	bundle install
	chown -R ${USER_NAME} ${GEM_HOME}
EOF

COPY --chmod=755 /.docker/api/entrypoint.sh /usr/bin/
ENTRYPOINT ["entrypoint.sh"]

USER ${USER_NAME}

RUN mkdir -p /${PROJECT_NAME}/tmp/sockets

RUN gh config set editor "code -w"

RUN <<-EOF
	set -e
	gem install solargraph-rails --pre
	solargraph download-core
	bundle exec yard gems || exit 0
EOF

RUN <<-EOF
	set -eu
	cat <<-'EOT' >> /home/${USER_NAME}/.bashrc
		eval "$(gh completion -s bash)"
		if [ "$SHLVL" -eq 2 ] ; then
		  script --flush ~/bashlog/script/`date "+%Y%m%d%H%M%S"`.log
		fi
		function might_exec_yard_gems() {
		  if [[ `history 1` =~ ^.*bundle( +((install|-+).*$)| *$) ]] ; then
		    printf "\x1b[1m%s\n" 'Running `yard gems` to generate docs for gems.'
		    bundle exec yard gems
		  fi
		}
		export PROMPT_COMMAND='history -a && might_exec_yard_gems'
		export HISTFILE=~/bashlog/.bash_history
	EOT
	mkdir -p /home/${USER_NAME}/bashlog/script
	touch /home/${USER_NAME}/bashlog/.bash_history
EOF

RUN mkdir -p /home/${USER_NAME}/.vscode-server/extensions

CMD ["bundle", "exec", "pumactl", "start"]
