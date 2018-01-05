library(cytovasTools)
library(flowFramePlus)


# we observed that the triton control has a false positive low-ssc tail on parameters 8 and 15.  
# There is also a false positive cloud on parameters 7 and 10.  If we use SSC-A between 8000 
# and 12500 we avoid most of this problem.
thresholds.from.triton = function(ffp, folderID=NA, fn=NA,  
                                  parameters=7:16, 
                                  ssc.limit=c(5000, 20000), 
                                  size.thresh=1e5, 
                                  cumm.prob=0.9999, 
                                  show=FALSE, show.fn="", 
                                  verbose=FALSE, schema = "EVENTS") {
  
  #the non-null parameters have an antibody
  nona_parameters<-which(!is.na(parameters(ffp$ffOrig)$desc))

  ssc.limit.tx=flowFramePlus:::bx(ssc.limit)
  size.thresh.tx = flowFramePlus:::bx(size.thresh)
  
  if (verbose) {
    btim = strptime(keyword(ff)$`$BTIM`, format = "%H:%M:%S")
    etim = strptime(keyword(ff)$`$ETIM`, format = "%H:%M:%S")
    tdiff = (etim - btim) * 60    # seconds
    cat(tdiff, "Sec... ")
  }
  tmp = flowFramePlus$new(Subset(ffp$ffOrig, rectangleGate("SSC-A" = ssc.limit)))
  
  #ttmp$plot(plist=c("695/40 Blue-A","SSC-A"))

  
  
  thresh = vector('numeric')
  kde = list()
  gde = list()  # the gaussian derivation
  if (verbose) {cat("kde... ")}
  for (i in 1:length(nona_parameters)) {
    pname = colnames(tmp$ffTxed)[nona_parameters[i]]
    kde[[i]] = KernSmooth::bkde(exprs(tmp$ffTxed)[,pname], bandwidth = 0.02, gridsize = 4001)
    gde[[i]] = cytovasTools:::fit_gaussian_base(kde[[i]], height = 0.005)
    thresh[i] = cytovasTools:::cumm_prob_thresh(gde[[i]], cumm.prob)
  }
  
  names(thresh) = colnames(tmp)[nona_parameters]
  #   bzone = 0.04
  #   thresh = thresh + bzone
  
  if (verbose) {cat("gates... ")}
  pgate = list()
  ngate = list()
  for (i in 1:length(nona_parameters)) {
    p = colnames(ff)[nona_parameters[i]]
    gexpr = paste("list('", p, "'=c(", thresh[i], ", Inf))", sep = "")
    pgate[[i]] = flowCore::rectangleGate(filterId = paste(p, "+", sep = ""), .gate = eval(parse(text = gexpr)))
    ngexpr = paste("list('", p, "'=c(-Inf, ", thresh[i], "))", sep = "")
    ngate[[i]] = flowCore::rectangleGate(filterId = paste(p, "-", sep = ""), .gate = eval(parse(text = ngexpr)))
  }
  
  # calculate false positives
  if (verbose) {cat("false pos... ")}
  ffg = Subset(ff, flowCore::rectangleGate("SSC-A" = c(-Inf, size.thresh)))
  res_fp = remove.background.events(ffg, pgate, verbose = verbose)
  ffg = res_fp$ff
  
  if (verbose) {cat("plotting... ")}
  if (show) {
    if (show.fn != "") {
      png(filename = show.fn, width = 1200, height = 800)
    }
    laymat = matrix(c(1,2,3,4,5,6,7,0,8,9,10,0), byrow = TRUE, ncol = 4)
    layout(laymat)
    par(mar = c(2, 2.5, 3, 1))
    for (i in 1:length(nona_parameters)) {
      p = colnames(ff)[nona_parameters[i]]
      pplot(ff, c(p, "SSC-A"), xlim = c(-.5, bx(5000)), main = p)
      left.edge = -2
      polygon(x = c(left.edge,thresh[i], 
                    thresh[i], 
                    left.edge), 
              y = c(0, 0, 5.4, 5.4), 
              col = '#0000000F')   # negative for param
      polygon(x = c(thresh[i], 
                    biexp.transform(262143), 
                    biexp.transform(262143), 
                    thresh[i]), 
              y = c(biexp.transform(263000), 
                    biexp.transform(263000), 
                    size.thresh, size.thresh), 
              col = '#0000000F')  # size
      yline(ssc.limit, lty = 'dotdash')
      # plot the kde's
      tkde = normalize_kde(kde[[i]])
      lines(tkde$x, 2.5 * tkde$y)
      tgde = normalize_kde(gde[[i]])
      lines(tgde$x, 2.5 * tgde$y, col = 'red')
      text(bx(300), bx(300), labels = sprintf("fp = %d (%.3f%%)", res_fp$n_fp[i], 100 * res_fp$n_fp[i] / res_fp$n_total), pos = 4, cex = 2)
      #       points(exprs(ffg)[,names(thresh)[i]], 
      #              exprs(ffg)[,"SSC-A"], 
      #              pch = 20, 
      #              cex = .3)
      #       if (p == "CD47") {
      #         polygon(xp.pe, yp.pe, col='#0000000F')
      #       }
      #       if (p == "AV") {
      #         polygon(xp.v500, yp.v500, col='#0000000F')
      #       }
    }
    if (show.fn != "") { 
      dev.off()
    }
    
    # clean up memory
    rm(ff, tmp)
  }
  return(list(thresh = thresh, kde = kde, pgate = pgate, ngate = ngate, fp = ffg))
}

# use positivity thresholds to gate out events that are negative for all colors
remove.background.events = function(ff, gate, verbose=FALSE) {
  
  # make the OR combination of all of the gates in the list of gates - THIS IS VERRRY SLOOOOW...
  #   pgate = gate[[1]]
  #   for (i in 2:length(gate)) {
  #     pgate = pgate | gate[[i]]
  #   }
  #   
  #   out = Subset (ff, pgate)
  
  nev = nrow(ff)
  bvec = rep(FALSE, length.out = nev)
  fp = vector(mode = 'numeric')
  for (i in 1:length(gate)) {
    if (verbose) {cat(i, ":", sep = "")}
    res = filter(ff, gate[[i]])
    bvec = bvec | res@subSet
    fp[i] = length(which(res@subSet))
    pctg = fp[i] / nev
    if (verbose) {cat(fp[i], sprintf(" (%.3f%%)", 100*pctg), " ")}
  }
  
  out = ff
  exprs(out) = exprs(out)[which(bvec),]
  
  return(list(ff = out, n_total = nev, n_fp = fp))
}