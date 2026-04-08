.PHONY: fmt fmt-check lint test check

fmt:
	stylua .

fmt-check:
	stylua --check .

lint:
	selene .

test:
	@if [ -d spec ] && find spec -type f -name '*_spec.lua' | grep -q .; then \
		busted; \
	else \
		echo "No spec/*_spec.lua files yet; skipping busted."; \
	fi

check: fmt-check lint test
