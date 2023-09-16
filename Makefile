.PHONY: watch-css build-css deploy
watch-css:
	tailwind -c ./tailwind.config.js -i ./assets/_src/css/styles.css -o ./assets/css/styles.css --watch

deploy:
	ansible-playbook -i hosts deploy.yaml
