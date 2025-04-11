{ config, lib, pkgs, ... }:

{
  options = {
    firefox.enable = lib.mkEnableOption "Enable firefox";
  };

  config = lib.mkIf config.firefox.enable {
  programs.firefox = {
    enable = true;
    preferences = {
      "browser.preferences.defaultPerformanceSettings.enabled" = true;
      "layers.acceleration.disabled" = false;
      "dom.security.https_only_mode" = true;
      "sidebar.verticalTabs" = true;
      "signon.rememberSignons" = false;
      "sidebar.revamp" = true;
      "extensions.formautofill.creditCards.enabled" = false;
      "browser.translations.neverTranslateLanguages" = "fr";
      "browser.toolbars.bookmarks.visibility" = "never";
      "browser.bookmarks.showMobileBookmarks" = false;
      "browser.contentblocking.category" = "standard";
      "browser.aboutConfig.showWarning" = false;
      "browser.newtabpage.activity-stream.showSponsored" = false;
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      "browser.newtabpage.activity-stream.default.sites" = "";
      "extensions.getAddons.showPane" = false;
      "extensions.htmlaboutaddons.recommendations.enabled" = false;
      "browser.discovery.enabled" = false;
      "browser.newtabpage.activity-stream.feeds.telemetry" = false;
      "browser.newtabpage.activity-stream.telemetry" = false;
      "browser.urlbar.addons.featureGate" = false;
      "browser.urlbar.fakespot.featureGate" = false;
      "browser.urlbar.mdn.featureGate" = false;
      "browser.urlbar.pocket.featureGate" = false;
      "browser.urlbar.weather.featureGate" = false;
      "browser.urlbar.yelp.featureGate" = false;
      "browser.formfill.enable" = false;
      "browser.search.separatePrivateDefault" = false;
      "browser.search.separatePrivateDefault.ui.enabled" = false;
      "signon.autofillForms" = false;
      "signon.formlessCapture.enabled" = false;
    };
  };
  };
}