#' Create rENA Accumulated Model based on Horizon of Observation Algorithm
#'
#' For multimodal data, this function creates the correct rENA accumulated model that can be used 
#' to create rENA sets for analysis.
#' @param data              Multimodal data.frame or data.table
#' @param Units             A vector of Strings describing the Units for ENA model
#' @param Conversation      A vector of Strings describing the Conversations took place in ENA model
#' @param Codes             A vector of Strings entailing the big C Codes of interest for ENA 
#' analysis
#' @param dataModeCol       Name of the column where the types of multimodal data is stored
#' @param modeObserve       Modes of data where actions are observable to all players
#' @param usersCol          Name of the column entailing the unique user tracking info
#' @param windowSize        Size of the moving stanza window, for looking backwards (for whole 
#' conversation, input 1)
#' @param useDT             Boolean parameter on whether to call hoo.horizon.DT() instead of 
#' hoo.horizon(). Default to FALSE
#' @param referenceMode     Modes of data that the reference line should be (default to all modes 
#' of data as in no restriction on the reference line). Note: if referenceMode differs from its 
#' default value, then useDT will automatically be reverted to FALSE
#' @param ...               Additional arguments to pass along to rENA ena.accumulate.data method
#' @return     an environment containing all relevant ENA accumulated model information to build 
#' ENA set upon
#' @export
#' @examples
#' accum = hoo.ena.accumulate.data(data = mock,
#'                                 Units = c("site", "userName"),
#'                                 Conversation = c("site"),
#'                                 Codes = c("Code1", "Code2", "Code3", "Code4"),
#'                                 dataModeCol = "data",
#'                                 modeObserve = "chat",
#'                                 usersCol = "userName",
#'                                 windowSize = 4)
#'
hoo.ena.accumulate.data = function(data, Units, Conversation, Codes,
                                   dataModeCol, modeObserve,
                                   usersCol,
                                   windowSize, 
                                   useDT = FALSE, 
                                   referenceMode = unique(data[[dataModeCol]]), ...)
{
  data = as.data.frame(data)
  ena_accum = rENA::ena.accumulate.data(units = data.frame(data[, Units]),
                                        conversation = data.frame(data[, Conversation]),
                                        codes = data.frame(data[, Codes]),
                                        window.size.back = windowSize, ...)
  if (all(referenceMode == unique(data[[dataModeCol]])) == F) {
    useDT = F
  }
  if (useDT == F) {
    hoo_adj = hoo.horizon(data = data,
                          Units = Units, Conversation = Conversation, Codes = Codes,
                          dataModeCol = dataModeCol, modeObserve = modeObserve,
                          usersCol = usersCol,
                          windowSize = windowSize, 
                          referenceMode = referenceMode)
  } else {
    hoo_adj = hoo.horizon.DT(data = data,
                             Units = Units, Conversation = Conversation, Codes = Codes,
                             dataModeCol = dataModeCol, modeObserve = modeObserve,
                             usersCol = usersCol,
                             windowSize = windowSize)
  }
  hoo_adj_ordered = data.frame(hoo_adj[order(match(hoo_adj$Group.1, 
                                                   ena_accum$adjacency.vectors.raw$ENA_UNIT)), ])
  rownames(hoo_adj_ordered) = 1:nrow(hoo_adj_ordered)
  colsOfAdjVecsRaw = which(grepl(colnames(ena_accum$adjacency.vectors.raw), 
                                 pattern = "adjacency.code", ignore.case = T))
  ena_accum$adjacency.vectors.raw = data.frame(ena_accum$adjacency.vectors.raw)
  ena_accum$adjacency.vectors.raw[, colsOfAdjVecsRaw] = 
    hoo_adj_ordered[, 2:(ncol(hoo_adj_ordered))]
  ena_accum$adjacency.vectors = ena_accum$adjacency.vectors.raw[, colsOfAdjVecsRaw]
  ena_accum$adjacency.vectors.raw = data.table::data.table(ena_accum$adjacency.vectors.raw)
  ena_accum$adjacency.vectors = data.table::data.table(ena_accum$adjacency.vectors)
  return(ena_accum)
}
