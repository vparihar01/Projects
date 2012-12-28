// Navigation menu
// --------------------------------------------------
var activeItem = null;
function closeSubMenu() {
	var n = document.getElementById("navigation");
	var lis = n.getElementsByTagName("li");
	for (var i = 0; i < lis.length; i++)
	{
		lis[i].className = lis[i].className.replace("hover", "");
	}
}
function initPage()
{
	var n = document.getElementById("navigation");
	if (n)
	{
		var lis = n.getElementsByTagName("li");
		for (var i = 0; i < lis.length; i++)
		{
			if (lis[i].className.indexOf("active") != -1) activeItem = lis[i];
			if (lis[i].parentNode.id == "navigation")
			{
				var a = lis[i].getElementsByTagName("a");
				a[0].onclick = function ()
				{
					var p = this.parentNode;
          if (p.className.indexOf("hover") != -1)
					{
						p.className = p.className.replace("hover", "");
						if (activeItem) activeItem.className = activeItem.className.replace("off", "active");
						if (activeItem && activeItem.getElementsByTagName("ul")[0]) activeItem.className += " hover";
					}
					else
					{
						closeSubMenu();	
						if (activeItem && activeItem) activeItem.className = activeItem.className.replace("off", "active");
						if (p.getElementsByTagName("ul")[0])
						{
							p.className += " hover";
							if (activeItem && p != activeItem) activeItem.className = activeItem.className.replace("active", "off");
						}
					}
					return false;
				}
			}
			else
			{
				lis[i].onmouseover = function()
				{
					this.className += " hover";
				}
				lis[i].onmouseout = function()
				{
					this.className = this.className.replace(" hover", "");
				}
			}
		}
	}
}

// Event listener for navigation menu
// --------------------------------------------------
if (window.addEventListener)
	window.addEventListener("load", initPage, false);
else if (window.attachEvent)
	window.attachEvent("onload", initPage);
