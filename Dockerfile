FROM dolfinus/arkenston-backend:base
RUN apk add --update --no-cache \
  libxml2-dev \
  libxslt-dev
COPY --from=dolfinus/arkenston-backend:build /usr/local/bundle /usr/local/bundle
COPY --chown=arkenston:arkenston app/ ./app/
COPY --chown=arkenston:arkenston bin/ ./bin/
COPY --chown=arkenston:arkenston config/ ./config/
COPY --chown=arkenston:arkenston db/ ./db/
COPY --chown=arkenston:arkenston lib/ ./lib/
COPY --chown=arkenston:arkenston public/ ./public/
COPY --chown=arkenston:arkenston vendor/ ./vendor/

USER arkenston
EXPOSE 3000
ENTRYPOINT ["./entrypoint.sh"]
