function getLastModifiedDate() {
  var d = new Date(document.lastModified);
  return d.toISOString().substring(0,10);
}
document.getElementById("lastmod").innerHTML = "Last modified " + getLastModifiedDate();
const specCount = document.querySelectorAll("tbody tr").length;
const visible = `
  tbody tr:not(.hiddenFeatureGroup, .hiddenSingleEngineFeature)`;
const includeSingleEngineSpecs = "Include single-engine specifications";
console.log(specCount);

const toggleSingleEngineSpecs = () => {
  if (button.textContent === includeSingleEngineSpecs) {
    button.textContent = "Exclude single-engine specifications";
    [...document.querySelectorAll("tr")].forEach(row => {
      if (row.querySelectorAll("s").length > 0) {
        row.classList.remove("hiddenSingleEngineFeature");
        row.classList.add("visibleSingleEngineFeature");
      }
    })
  } else {
    button.textContent = includeSingleEngineSpecs;
    [...document.querySelectorAll("tr")].forEach(row => {
      if (row.querySelectorAll("s").length > 0) {
        row.classList.add("hiddenSingleEngineFeature");
        row.classList.remove("visibleSingleEngineFeature");
      }
    })
  }
  const visibleSpecs = document.querySelectorAll(visible).length;
  countMessage.textContent = `${visibleSpecs} specifications currently shown`;
}

const toggleFeatureGroups = (e) => {
  const featureGroup = e.target.className;
  for (row of document.querySelectorAll(`tbody tr:not(.${featureGroup})`)) {
    if (row.classList.contains("hiddenFeatureGroup")) {
      row.classList.remove("hiddenFeatureGroup");
      row.classList.add("visibleFeatureGroup");
    } else {
      row.classList.add("hiddenFeatureGroup");
      row.classList.remove("visibleFeatureGroup");
    }
  }
  const visibleSpecs = document.querySelectorAll(visible).length;
  countMessage.textContent = `${visibleSpecs} specifications currently shown`;
}

const countMessage = document.querySelector("p b");
const button = document.querySelector("button");

button.addEventListener("click", toggleSingleEngineSpecs);

for (const u of document.querySelectorAll("u")) {
  u.addEventListener("click", toggleFeatureGroups);
}

document.addEventListener("click",function(b){try{var p=function(a){return v&&a.getAttribute("data-sort-alt")||a.getAttribute("data-sort")||a.innerText},q=function(a,c){a.className=a.className.replace(w,"")+c},f=function(a,c){return a.nodeName===c?a:f(a.parentNode,c)},w=/ dir-(u|d) /,v=b.shiftKey||b.altKey,e=f(b.target,"TH"),r=f(e,"TR"),g=f(r,"TABLE");if(/\bsortable\b/.test(g.className)){var h,d=r.cells;for(b=0;b<d.length;b++)d[b]===e?h=e.getAttribute("data-sort-col")||b:q(d[b],"");d=" dir-d ";-1!==
e.className.indexOf(" dir-d ")&&(d=" dir-u ");q(e,d);var k=g.tBodies[0],l=[].slice.call(k.rows,0),t=" dir-u "===d;l.sort(function(a,c){var m=p((t?a:c).cells[h]),n=p((t?c:a).cells[h]);return isNaN(m-n)?m.localeCompare(n):m-n});for(var u=k.cloneNode();l.length;)u.appendChild(l.splice(0,1)[0]);g.replaceChild(u,k)}}catch(a){}});
[...document.querySelectorAll("tr")].forEach(row => { if (row.querySelectorAll("s").length > 0) { row.classList.add("hiddenSingleEngineFeature") }})
const visibleSpecs = document.querySelectorAll(visible).length;
countMessage.textContent = `${visibleSpecs} specifications currently shown`;
