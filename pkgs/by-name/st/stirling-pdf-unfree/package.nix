{ stirling-pdf }:

(stirling-pdf.override {
  withAdditionalFeatures = true;
}).overrideAttrs
  {
    strictDeps = true;
  }
