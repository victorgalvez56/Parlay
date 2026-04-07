APP_NAME = LangLens
APP_BUNDLE = $(APP_NAME).app
SIGN_ID = Apple Development: Victor Galvez (7BVX533M64)

.PHONY: dev watch build bundle run install clean dmg

# Dev: debug build + relaunch app bundle (~2-3s incremental)
dev:
	@swift build 2>&1 | tail -5
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@cp .build/debug/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@codesign --force --sign "$(SIGN_ID)" --entitlements LangLens/Resources/LangLens.entitlements $(APP_BUNDLE)
	@pkill -x $(APP_NAME) 2>/dev/null || true
	@sleep 0.3
	@open $(APP_BUNDLE)
	@echo "✅ dev ready"

# Watch: auto-rebuild + relaunch on any .swift change
watch:
	@echo "👀 Watching for changes... (Ctrl+C to stop)"
	@make dev 2>&1 || true
	@fswatch -o -e ".*" -i "\\.swift$$" LangLens/ | while read; do \
		echo "🔄 Change detected, rebuilding..."; \
		make dev 2>&1 || echo "❌ Build failed"; \
	done

# Release build
build:
	swift build -c release

bundle: build
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp .build/release/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	codesign --force --sign "$(SIGN_ID)" --entitlements LangLens/Resources/LangLens.entitlements $(APP_BUNDLE)
	@echo "✅ $(APP_BUNDLE) ready"

run: bundle
	open $(APP_BUNDLE)

install: bundle
	cp -R $(APP_BUNDLE) /Applications/$(APP_BUNDLE)
	@echo "✅ Installed to /Applications/$(APP_BUNDLE)"

dmg: bundle
	@echo "📦 Creating DMG..."
	@rm -rf /tmp/$(APP_NAME)-dmg
	@mkdir /tmp/$(APP_NAME)-dmg
	@cp -R $(APP_BUNDLE) /tmp/$(APP_NAME)-dmg/
	@ln -s /Applications /tmp/$(APP_NAME)-dmg/Applications
	@hdiutil create -volname "$(APP_NAME)" \
		-srcfolder /tmp/$(APP_NAME)-dmg \
		-ov -format UDZO \
		$(APP_NAME).dmg
	@rm -rf /tmp/$(APP_NAME)-dmg
	@echo "✅ $(APP_NAME).dmg ready"

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
