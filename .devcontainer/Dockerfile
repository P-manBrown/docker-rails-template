# syntax=docker/dockerfile:1
ARG RUBY_IMAGE_TAG
FROM ruby:${RUBY_IMAGE_TAG}

ARG GIT_VERSION=2.38.0
ARG PROJECT_NAME
ARG RUBYGEMS_VERSION
ARG USER_NAME=ruby
ENV TZ=Asia/Tokyo

RUN <<-EOF
	set -ex
	rm -f /etc/apt/apt.conf.d/docker-clean
	cat <<-'EOT' > /etc/apt/apt.conf.d/keep-cache
		Binary::apt::APT::Keep-Downloaded-Packages "true";
	EOT
EOF
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt,sharing=locked <<-EOF
	set -eux
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	| dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/\
	githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
	| tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	apt-get update -qq
	apt-get install -qy bash-completion gettext gh libcurl4-gnutls-dev
	cd /usr/local/src
	wget https://github.com/git/git/archive/refs/tags/v${GIT_VERSION}.tar.gz
	tar -xzf v${GIT_VERSION}.tar.gz
	cd git-${GIT_VERSION}
	make prefix=/usr/local all -j "$(nproc)"
	make prefix=/usr/local install
EOF

RUN gem update --system ${RUBYGEMS_VERSION}

COPY --chmod=755 /.docker/api/entrypoint.sh /usr/bin/
ENTRYPOINT ["entrypoint.sh"]

RUN adduser ${USER_NAME}
RUN chown -R ${USER_NAME} ${GEM_HOME}
USER ${USER_NAME}

WORKDIR /home/${USER_NAME}/${PROJECT_NAME}
COPY --chown=${USER_NAME} Gemfile* /home/${USER_NAME}/${PROJECT_NAME}/
RUN --mount=type=secret,uid=1000,id=github-credentials,required \
--mount=type=cache,uid=1000,target=/home/${USER_NAME}/.cache/bundle <<-EOF
	set -aeu
	. /run/secrets/github-credentials
	GEM_HOME=/home/${USER_NAME}/.cache/bundle bundle install
	cp -aRT /home/${USER_NAME}/.cache/bundle ${GEM_HOME}
EOF
RUN mkdir -p /home/${USER_NAME}/${PROJECT_NAME}/tmp/sockets

RUN gh config set editor "code -w"

RUN <<-EOF
	set -eux
	gem install solargraph-rails
	solargraph download-core
	mkdir -p /home/${USER_NAME}/.yard/gem_index
EOF

RUN <<-EOF
	set -eux
	cat <<-'EOT' >> /home/${USER_NAME}/.bashrc
		eval "$(gh completion -s bash)"
		if [ "$SHLVL" -eq 2 ]; then
		  script --flush ~/bashlog/script/`date "+%Y%m%d%H%M%S"`.log
		fi
		might_exec_yard_gems() {
		  if [[ `history 1` =~ ^.*bundle( +((install|-+).*$)| *$) ]]; then
		    printf '\x1b[1m%s\n' 'Running `yard gems` to generate docs for gems.'
		    for i in {1..3}
		    do
		      yard gems -quiet && break
		    done
		  fi
		}
		export PROMPT_COMMAND='history -a && might_exec_yard_gems'
		export PS4='+\e[32m[\t]\e[34m[${BASH_SOURCE[0]##*/}:${LINENO}]\e[m> '
		export HISTFILE=~/bashlog/.bash_history
	EOT
	mkdir -p /home/${USER_NAME}/bashlog/script
	touch /home/${USER_NAME}/bashlog/.bash_history
EOF

RUN mkdir -p /home/${USER_NAME}/.vscode-server/extensions

EXPOSE 3000

CMD ["bundle", "exec", "pumactl", "start"]
