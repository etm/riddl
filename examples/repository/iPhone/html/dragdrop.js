/*
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 *
 */

/**
 * @projectDescription Drag and Drop

 * @author   Łukasz Lipiński uzza17@gmail.com
 */
document.onmousedown = function(e) {
    e = (e || event);

    var target = e.target || e.srcElement;

    if (target.tagName == 'HTML')
        return;

    while (target != document.body && (target.className || "").indexOf("resource") == -1) {
        target = target.parentNode || target.parentElement;
    }

    if ((target.className || "").indexOf("resource") == -1)
        return;

    target = target.parentNode;

    var sx = e.clientX, sy = e.clientY,
        dx = 0, dy = 0,
        l = target.offsetLeft,
        t = target.offsetTop;

    if (e.preventDefault) {
        e.preventDefault();
    }

    document.onmousemove = function(e) {
        e = (e || event);
    
        dx = e.clientX - sx;
        dy = e.clientY - sy;
    
        target.style.left = (l + dx) + "px";
        target.style.top  = (t + dy) + "px";

        return false;
    }
};

document.onmouseup = function(e) {
    document.onmousemove = null;
};
