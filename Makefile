.PHONY: watch-css build-css deploy
watch-css:
	npx tailwindcss -c ./tailwind.config.js -i ./assets/_css/styles.css -o ./assets/css/styles.css --watch

# build-css:
# 	NODE_ENV=production npx tailwindcss -c ./tailwind.config.js -i ./assets/_css/styles.css -o ./css/styles.css --minify

deploy:
	ansible-playbook -i hosts deploy.yaml
