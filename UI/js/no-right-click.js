document.onselectstart =
document.oncontextmenu =
document.ondragstart = function() {
    return window.event && event.srcElement.tagName == "INPUT" || false;
};