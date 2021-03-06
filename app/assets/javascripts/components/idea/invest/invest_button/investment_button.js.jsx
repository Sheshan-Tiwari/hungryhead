var InvestButton = React.createClass({

  getInitialState: function () {
    return {loading: false, invested: this.props.invested, investable: this.props.idea.investable};
  },

  openInvestBox: function () {
    this.setState({loading: true});
    $('body').append($('<div>', {class: 'investment_modal', id: 'investment_modal'}));
    React.render(
      <Invest idea={this.props.idea} key={Math.random()}  />,
      document.getElementById('investment_modal')
    );
    this.setState({loading: false});
    $("#investPopup").modal('show');
  },

  componentDidMount: function(){
    var self = this;
    $.pubsub('subscribe', 'idea_invested', function(msg, data){
      self.setState({invested: true});
    });
  },

  openInvestedBox: function() {
    swal({
      title: "Error!",
      text: "Hey! You have already invested",
      type: "error",
      confirmButtonText: "",
      timer: 2000
    });
  },

  render: function() {
    var classes = classNames({
      'fa fa-dollar': true
    });

    var invested_classes = classNames({
      'fs-13 pointer padding-5 bold p-l-10 p-r-10 pull-right m-r-10': true,
      'main-button': !this.state.invested && this.state.investable,
      'main-button': !this.state.investable,
      'invested': this.state.invested
    });

    if(this.state.invested) {
      var buttonText = <a className={invested_classes} onClick={this.openInvestedBox}><i className={classes}></i> Invested</a>;
    } else {
      var buttonText = <a className={invested_classes} onClick={this.openInvestBox}><i className={classes}></i> Invest</a>;
    }

    return(
      buttonText
    )
  }
});
